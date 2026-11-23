package com.fetu.app

import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.DnsResolver
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.system.OsConstants
import android.util.Log
import io.nekohasekai.libbox.ExchangeContext
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NetworkInterface as LibboxNetworkInterface
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.Notification
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.RoutePrefixIterator
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet4Address
import java.net.Inet6Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/** Мост PlatformInterface для libbox (sing-box) на Android. */
class FetuPlatformBridge(
    private val vpnService: VpnService,
    private val onTunOpened: (ParcelFileDescriptor) -> Unit,
) : PlatformInterface {

    private val connectivityManager =
        vpnService.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val dnsExecutor: ExecutorService = Executors.newCachedThreadPool()
    private var defaultNetworkCallback: ConnectivityManager.NetworkCallback? = null
    @Volatile
    private var underlyingNetwork: Network? = null

    override fun localDNSTransport(): LocalDNSTransport = AndroidLocalDnsTransport()

    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

    override fun autoDetectInterfaceControl(fd: Int) {
        if (!vpnService.protect(fd)) {
            Log.w(TAG, "Failed to protect outbound socket")
        }
    }

    override fun openTun(options: TunOptions): Int {
        val builder = vpnService.Builder()
            .setSession("Fetu")
            .setMtu(options.mtu.takeIf { it > 0 } ?: 1500)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        val inet4Addresses = options.inet4Address
        while (inet4Addresses.hasNext()) {
            val prefix = inet4Addresses.next()
            builder.addAddress(prefix.address(), prefix.prefix())
        }

        val inet6Addresses = options.inet6Address
        while (inet6Addresses.hasNext()) {
            val prefix = inet6Addresses.next()
            builder.addAddress(prefix.address(), prefix.prefix())
        }

        if (options.autoRoute) {
            val dnsServer = options.dnsServerAddress
            if (dnsServer != null && dnsServer.value.isNotEmpty()) {
                builder.addDnsServer(dnsServer.value)
            }

            addRoutes(builder, options.inet4RouteAddress, options.inet4RouteRange)
            addRoutes(builder, options.inet6RouteAddress, options.inet6RouteRange)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                excludeRoutes(builder, options.inet4RouteExcludeAddress)
                excludeRoutes(builder, options.inet6RouteExcludeAddress)
            }

            val includePackages = options.includePackage
            while (includePackages.hasNext()) {
                val pkg = includePackages.next()
                try {
                    builder.addAllowedApplication(pkg)
                } catch (_: PackageManager.NameNotFoundException) {
                }
            }

            val excludePackages = options.excludePackage
            while (excludePackages.hasNext()) {
                val pkg = excludePackages.next()
                try {
                    builder.addDisallowedApplication(pkg)
                } catch (_: PackageManager.NameNotFoundException) {
                }
            }
        }

        if (options.isHTTPProxyEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val bypassList = mutableListOf<String>()
            val bypass = options.httpProxyBypassDomain
            while (bypass.hasNext()) {
                bypassList.add(bypass.next())
            }
            builder.setHttpProxy(
                ProxyInfo.buildDirectProxy(
                    options.httpProxyServer,
                    options.httpProxyServerPort,
                    bypassList,
                ),
            )
        }

        val pfd = builder.establish()
            ?: throw IllegalStateException("VpnService.Builder.establish() returned null")
        onTunOpened(pfd)
        return pfd.fd
    }

    private fun addRoutes(
        builder: VpnService.Builder,
        explicitRoutes: RoutePrefixIterator,
        autoRoutes: RoutePrefixIterator,
    ) {
        var addedExplicit = false
        while (explicitRoutes.hasNext()) {
            val prefix = explicitRoutes.next()
            builder.addRoute(prefix.address(), prefix.prefix())
            addedExplicit = true
        }
        if (!addedExplicit) {
            while (autoRoutes.hasNext()) {
                val prefix = autoRoutes.next()
                builder.addRoute(prefix.address(), prefix.prefix())
            }
        }
    }

    private fun excludeRoutes(builder: VpnService.Builder, excluded: RoutePrefixIterator) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        while (excluded.hasNext()) {
            val prefix = excluded.next()
            try {
                val ipPrefix = android.net.IpPrefix(
                    InetAddress.getByName(prefix.address()),
                    prefix.prefix(),
                )
                builder.excludeRoute(ipPrefix)
            } catch (_: Exception) {
            }
        }
    }

    override fun writeLog(message: String) {
        // Правило 16: не пишем пользовательские IP/DNS-запросы в production-логи.
    }

    override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int,
    ): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return -1
        }
        return try {
            connectivityManager.getConnectionOwnerUid(
                ipProtocol,
                InetSocketAddress(sourceAddress, sourcePort),
                InetSocketAddress(destinationAddress, destinationPort),
            )
        } catch (_: Exception) {
            -1
        }
    }

    override fun packageNameByUid(uid: Int): String {
        val packages = vpnService.packageManager.getPackagesForUid(uid)
        return packages?.firstOrNull() ?: ""
    }

    override fun uidByPackageName(packageName: String): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                vpnService.packageManager.getPackageUid(
                    packageName,
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                vpnService.packageManager.getPackageUid(packageName, 0)
            }
        } catch (_: PackageManager.NameNotFoundException) {
            -1
        }
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        closeDefaultInterfaceMonitor(listener)
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                underlyingNetwork = network
                notifyInterface(network, listener)
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities,
            ) {
                underlyingNetwork = network
                notifyInterface(network, listener, networkCapabilities)
            }

            override fun onLost(network: Network) {
                if (underlyingNetwork == network) {
                    underlyingNetwork = findNonVpnNetwork(excluding = network)
                }
                val fallback = underlyingNetwork
                if (fallback != null) {
                    notifyInterface(fallback, listener)
                } else {
                    listener.updateDefaultInterface("", -1, false, false)
                }
            }
        }
        defaultNetworkCallback = callback
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
            .build()
        connectivityManager.registerNetworkCallback(request, callback)

        val initialNetwork = findNonVpnNetwork()
        if (initialNetwork != null) {
            underlyingNetwork = initialNetwork
            notifyInterface(initialNetwork, listener)
        }
    }

    private fun findNonVpnNetwork(excluding: Network? = null): Network? {
        val active = connectivityManager.activeNetwork
        if (active != null && active != excluding && isPhysicalInternetNetwork(active)) {
            return active
        }
        @Suppress("DEPRECATION")
        val all = connectivityManager.allNetworks
        return all.firstOrNull { net ->
            net != excluding && isPhysicalInternetNetwork(net, requireValidated = true)
        } ?: all.firstOrNull { net ->
            net != excluding && isPhysicalInternetNetwork(net, requireValidated = false)
        }
    }

    private fun isPhysicalInternetNetwork(
        network: Network,
        requireValidated: Boolean = false,
    ): Boolean {
        val caps = connectivityManager.getNetworkCapabilities(network) ?: return false
        val hasInternet = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)
        if (!hasInternet) return false
        return !requireValidated || caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    private fun notifyInterface(
        network: Network,
        listener: InterfaceUpdateListener,
        capsOverride: NetworkCapabilities? = null,
    ) {
        val linkProps = connectivityManager.getLinkProperties(network) ?: return
        val ifName = linkProps.interfaceName ?: return
        val ifIndex = try {
            NetworkInterface.getByName(ifName)?.index ?: -1
        } catch (_: Exception) {
            -1
        }
        if (ifIndex < 0) return

        val caps = capsOverride ?: connectivityManager.getNetworkCapabilities(network)
        val isExpensive = caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false
        val isConstrained = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_TEMPORARILY_NOT_METERED) == false && isExpensive
        } else {
            false
        }
        listener.updateDefaultInterface(ifName, ifIndex, isExpensive, isConstrained)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        defaultNetworkCallback?.let { cb ->
            try {
                connectivityManager.unregisterNetworkCallback(cb)
            } catch (_: Exception) {
            }
            defaultNetworkCallback = null
        }
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val list = mutableListOf<LibboxNetworkInterface>()
        val interfaces = NetworkInterface.getNetworkInterfaces()
        while (interfaces != null && interfaces.hasMoreElements()) {
            val netIf = interfaces.nextElement()
            if (!netIf.isUp) continue
            val addresses = mutableListOf<String>()
            for (ifa in netIf.interfaceAddresses) {
                val hostAddr = ifa.address?.hostAddress?.substringBefore('%') ?: continue
                addresses.add("$hostAddr/${ifa.networkPrefixLength}")
            }
            if (addresses.isEmpty()) continue

            val mapped = LibboxNetworkInterface().apply {
                index = netIf.index
                mtu = netIf.mtu
                name = netIf.name
                this.addresses = ListStringIterator(addresses)
                flags = buildFlags(netIf)
                type = Libbox.InterfaceTypeOther
                dnsServer = ListStringIterator(emptyList())
                metered = false
            }
            list.add(mapped)
        }
        return object : NetworkInterfaceIterator {
            private var pos = 0
            override fun hasNext(): Boolean = pos < list.size
            override fun next(): LibboxNetworkInterface = list[pos++]
        }
    }

    private fun buildFlags(netIf: NetworkInterface): Int {
        var flags = 0
        if (netIf.isUp) flags = flags or 1
        if (netIf.isLoopback) flags = flags or 8
        if (netIf.isPointToPoint) flags = flags or 16
        if (netIf.supportsMulticast()) flags = flags or 4096
        return flags
    }

    override fun underNetworkExtension(): Boolean = false

    override fun includeAllNetworks(): Boolean = false

    override fun readWIFIState(): WIFIState? = null

    override fun systemCertificates(): StringIterator = ListStringIterator(emptyList())

    override fun clearDNSCache() {}

    override fun sendNotification(notification: Notification) {}

    fun shutdown() {
        defaultNetworkCallback?.let { cb ->
            try {
                connectivityManager.unregisterNetworkCallback(cb)
            } catch (_: Exception) {
            }
            defaultNetworkCallback = null
        }
        underlyingNetwork = null
        dnsExecutor.shutdownNow()
    }

    private inner class AndroidLocalDnsTransport : LocalDNSTransport {
        override fun raw(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

        override fun lookup(ctx: ExchangeContext, network: String, domain: String) {
            val cleanDomain = domain.trimEnd('.')
            val physicalNetwork = underlyingNetwork ?: findNonVpnNetwork()
            try {
                val addrs = if (physicalNetwork != null) {
                    physicalNetwork.getAllByName(cleanDomain)
                } else {
                    InetAddress.getAllByName(cleanDomain)
                }
                val filtered = addrs.filter { addr ->
                    when (network) {
                        "ip4" -> addr is Inet4Address
                        "ip6" -> addr is Inet6Address
                        else -> true
                    }
                }.mapNotNull { it.hostAddress }
                ctx.success(filtered.joinToString("\n"))
            } catch (_: Exception) {
                ctx.errnoCode(OsConstants.EAI_FAIL)
            }
        }

        override fun exchange(ctx: ExchangeContext, message: ByteArray) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                ctx.errnoCode(OsConstants.ENOSYS)
                return
            }
            val physicalNetwork = underlyingNetwork ?: findNonVpnNetwork()
            if (physicalNetwork == null) {
                ctx.errnoCode(OsConstants.ENETUNREACH)
                return
            }
            val signal = CancellationSignal()
            val latch = CountDownLatch(1)
            val completed = AtomicBoolean(false)
            ctx.onCancel {
                signal.cancel()
                if (completed.compareAndSet(false, true)) {
                    ctx.errnoCode(OsConstants.ECANCELED)
                }
                latch.countDown()
            }
            try {
                DnsResolver.getInstance().rawQuery(
                    physicalNetwork,
                    message,
                    DnsResolver.FLAG_EMPTY,
                    dnsExecutor,
                    signal,
                    object : DnsResolver.Callback<ByteArray> {
                        override fun onAnswer(answer: ByteArray, rcode: Int) {
                            try {
                                if (completed.compareAndSet(false, true)) {
                                    if (rcode == 0) {
                                        ctx.rawSuccess(answer)
                                    } else {
                                        ctx.errorCode(rcode)
                                    }
                                }
                            } finally {
                                latch.countDown()
                            }
                        }

                        override fun onError(error: DnsResolver.DnsException) {
                            try {
                                if (completed.compareAndSet(false, true)) {
                                    ctx.errnoCode(OsConstants.EIO)
                                }
                            } finally {
                                latch.countDown()
                            }
                        }
                    },
                )
            } catch (_: Exception) {
                if (completed.compareAndSet(false, true)) {
                    ctx.errnoCode(OsConstants.EIO)
                }
                latch.countDown()
                return
            }
            try {
                if (!latch.await(10, TimeUnit.SECONDS)) {
                    signal.cancel()
                    if (completed.compareAndSet(false, true)) {
                        ctx.errnoCode(OsConstants.ETIMEDOUT)
                    }
                }
            } catch (_: InterruptedException) {
                signal.cancel()
                if (completed.compareAndSet(false, true)) {
                    ctx.errnoCode(OsConstants.EINTR)
                }
            }
        }
    }

    private class ListStringIterator(private val items: List<String>) : StringIterator {
        private var index = 0
        override fun hasNext(): Boolean = index < items.size
        override fun len(): Int = items.size
        override fun next(): String = items[index++]
    }

    private companion object {
        const val TAG = "FetuPlatformBridge"
    }
}
