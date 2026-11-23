package com.fetu.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.CommandClient
import io.nekohasekai.libbox.CommandClientHandler
import io.nekohasekai.libbox.CommandClientOptions
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.Connections
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.OutboundGroupIterator
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.StatusMessage
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.SystemProxyStatus
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/** Android VpnService с интегрированным нативным ядром sing-box (libbox). */
class FetuVpnService : VpnService() {

    private val serviceExecutor = Executors.newSingleThreadExecutor()
    private var platformBridge: FetuPlatformBridge? = null
    private var boxService: BoxService? = null
    private var commandServer: CommandServer? = null
    private var commandClient: CommandClient? = null
    private var tunPfd: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
        ensureLibboxSetup(applicationContext)
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val config = intent?.getStringExtra(EXTRA_CONFIG)

        when (action) {
            ACTION_DISCONNECT -> {
                serviceExecutor.execute {
                    stopTunnelLocked(updateToDisconnected = true)
                    stopSelf()
                }
            }
            ACTION_RELOAD -> {
                if (config.isNullOrBlank()) {
                    return START_NOT_STICKY
                }
                serviceExecutor.execute {
                    reloadTunnelLocked(config)
                }
            }
            ACTION_CONNECT, null -> {
                if (config.isNullOrBlank()) {
                    Log.w(TAG, "VPN start ignored: config missing")
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
                promoteToForeground()
                updateStatus("connecting")
                serviceExecutor.execute {
                    startTunnelLocked(config)
                }
            }
            else -> {
                stopSelf(startId)
            }
        }
        return START_NOT_STICKY
    }

    private fun promoteToForeground() {
        val notification = buildNotification("Fetu", "Подключение к защищённому туннелю")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun ensureCommandServerLocked() {
        if (commandServer != null) return
        val server = Libbox.newCommandServer(
            object : CommandServerHandler {
                override fun getSystemProxyStatus(): SystemProxyStatus = SystemProxyStatus()
                override fun postServiceClose() {
                    serviceExecutor.execute {
                        stopTunnelLocked(updateToDisconnected = true)
                        stopSelf()
                    }
                }
                override fun serviceReload() {}
                override fun setSystemProxyEnabled(isEnabled: Boolean) {}
            },
            100,
        )
        server.start()
        commandServer = server

        val options = CommandClientOptions().apply {
            command = Libbox.CommandStatus
            statusInterval = 1_000_000_000L // 1 секунда в наносекундах
        }
        val client = Libbox.newCommandClient(
            object : CommandClientHandler {
                override fun clearLogs() {}
                override fun connected() {}
                override fun disconnected(message: String?) {}
                override fun initializeClashMode(modeList: StringIterator?, currentMode: String?) {}
                override fun updateClashMode(newMode: String?) {}
                override fun writeConnections(message: Connections?) {}
                override fun writeGroups(message: OutboundGroupIterator?) {}
                override fun writeLogs(messageList: StringIterator?) {}
                override fun writeStatus(message: StatusMessage?) {
                    if (message == null || !message.trafficAvailable) return
                    val map = mapOf<String, Any>(
                        "uploadBytes" to message.uplinkTotal,
                        "downloadBytes" to message.downlinkTotal,
                        "uploadSpeed" to message.uplink,
                        "downloadSpeed" to message.downlink,
                        "ping" to 0,
                    )
                    latestMetrics.set(map)
                    onMetricsUpdated?.invoke(map)
                }
            },
            options,
        )
        try {
            client.connect()
            commandClient = client
        } catch (e: Exception) {
            Log.w(TAG, "CommandClient metrics subscription unavailable: ${e.javaClass.simpleName}")
        }
    }

    private fun startTunnelLocked(configJson: String) {
        try {
            Libbox.checkConfig(configJson)
            stopTunnelLocked(updateToDisconnected = false)

            val bridge = FetuPlatformBridge(this) { newPfd ->
                val previous = tunPfd
                tunPfd = newPfd
                try {
                    previous?.close()
                } catch (_: Exception) {
                }
            }
            platformBridge = bridge

            ensureCommandServerLocked()
            val service = Libbox.newService(configJson, bridge)
            service.start()
            boxService = service
            commandServer?.setService(service)

            updateStatus("connected")
            updateForegroundNotification("Fetu", "Защищённое соединение активно")
        } catch (e: Exception) {
            // Правило 16: в лог и ошибки не передаём сырые сообщения ядра (могут содержать IP/домены).
            Log.e(TAG, "Failed to start sing-box tunnel: ${e.javaClass.simpleName}")
            stopTunnelLocked(updateToDisconnected = false)
            updateStatus("error")
            onError?.invoke(e.javaClass.simpleName)
            stopSelf()
        }
    }

    private fun reloadTunnelLocked(configJson: String) {
        try {
            Libbox.checkConfig(configJson)
            val bridge = platformBridge ?: run {
                startTunnelLocked(configJson)
                return
            }

            // Закрываем старый экземпляр sing-box и прежний TUN fd до открытия нового.
            val oldService = boxService
            boxService = null
            commandServer?.setService(null)
            try {
                oldService?.close()
            } catch (_: Exception) {
            }
            try {
                tunPfd?.close()
            } catch (_: Exception) {
            }
            tunPfd = null

            val newService = Libbox.newService(configJson, bridge)
            newService.start()
            boxService = newService
            commandServer?.setService(newService)
            updateStatus("connected")
        } catch (e: Exception) {
            Log.e(TAG, "Live reload failed: ${e.javaClass.simpleName}")
            stopTunnelLocked(updateToDisconnected = false)
            updateStatus("error")
            onError?.invoke(e.javaClass.simpleName)
            stopSelf()
        }
    }

    private fun stopTunnelLocked(updateToDisconnected: Boolean) {
        commandServer?.setService(null)
        try {
            boxService?.close()
        } catch (_: Exception) {
        }
        boxService = null

        try {
            commandClient?.disconnect()
        } catch (_: Exception) {
        }
        commandClient = null

        try {
            commandServer?.close()
        } catch (_: Exception) {
        }
        commandServer = null

        platformBridge?.shutdown()
        platformBridge = null

        try {
            tunPfd?.close()
        } catch (_: Exception) {
        }
        tunPfd = null

        latestMetrics.set(emptyMetrics())
        if (updateToDisconnected) {
            updateStatus("disconnected")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onRevoke() {
        // Инвариант #4: при отзыве VPN-разрешения останавливаем туннель.
        serviceExecutor.execute {
            stopTunnelLocked(updateToDisconnected = true)
            stopSelf()
        }
        super.onRevoke()
    }

    override fun onDestroy() {
        try {
            val future = serviceExecutor.submit {
                stopTunnelLocked(updateToDisconnected = true)
            }
            future.get(2, java.util.concurrent.TimeUnit.SECONDS)
        } catch (_: Exception) {
        } finally {
            serviceExecutor.shutdownNow()
        }
        super.onDestroy()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Fetu",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Tunnel status"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun updateForegroundNotification(title: String, text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(title, text))
    }

    private fun buildNotification(title: String, text: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(this, 0, it, pendingFlags)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .apply {
                if (contentIntent != null) setContentIntent(contentIntent)
            }
            .build()
    }

    companion object {
        private const val TAG = "FetuVpnService"
        private const val CHANNEL_ID = "fetu_tunnel_channel"
        private const val NOTIFICATION_ID = 1001

        const val ACTION_CONNECT = "com.fetu.app.ACTION_CONNECT"
        const val ACTION_DISCONNECT = "com.fetu.app.ACTION_DISCONNECT"
        const val ACTION_RELOAD = "com.fetu.app.ACTION_RELOAD"
        const val EXTRA_CONFIG = "config"

        private val libboxInitialized = AtomicBoolean(false)
        private val statusRef = AtomicReference("disconnected")
        private val latestMetrics = AtomicReference(emptyMetrics())

        @Volatile
        var onStatusChanged: ((String) -> Unit)? = null

        @Volatile
        var onMetricsUpdated: ((Map<String, Any>) -> Unit)? = null

        @Volatile
        var onError: ((String) -> Unit)? = null

        val currentStatus: String
            get() = statusRef.get()

        fun currentMetricsMap(): Map<String, Any> = latestMetrics.get()

        private fun updateStatus(status: String) {
            statusRef.set(status)
            onStatusChanged?.invoke(status)
        }

        private fun emptyMetrics(): Map<String, Any> = mapOf(
            "uploadBytes" to 0L,
            "downloadBytes" to 0L,
            "uploadSpeed" to 0L,
            "downloadSpeed" to 0L,
            "ping" to 0,
        )

        fun ensureLibboxSetup(context: Context) {
            if (!libboxInitialized.compareAndSet(false, true)) return
            try {
                val baseDir = File(context.filesDir, "sing-box").apply { mkdirs() }
                val workDir = File(baseDir, "working").apply { mkdirs() }
                val tempDir = File(context.cacheDir, "sing-box-tmp").apply { mkdirs() }
                val options = SetupOptions().apply {
                    basePath = baseDir.absolutePath
                    workingPath = workDir.absolutePath
                    tempPath = tempDir.absolutePath
                    fixAndroidStack = true
                }
                Libbox.setup(options)
            } catch (e: Throwable) {
                libboxInitialized.set(false)
                Log.e(TAG, "Libbox setup failed: ${e.javaClass.simpleName}")
            }
        }
    }
}
