package com.fetu.app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.nekohasekai.libbox.Libbox

/** Связывает Flutter Platform Channel с нативным VPN-сервисом libbox. */
class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingConnectConfig: String? = null
    private var pendingConnectResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FetuVpnService.ensureLibboxSetup(applicationContext)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = methodChannel

        FetuVpnService.onStatusChanged = { status ->
            runOnUiThread {
                channel?.invokeMethod("onStatusChanged", status)
            }
        }
        FetuVpnService.onMetricsUpdated = { metrics ->
            runOnUiThread {
                channel?.invokeMethod("onMetricsUpdated", metrics)
            }
        }
        FetuVpnService.onError = { error ->
            runOnUiThread {
                channel?.invokeMethod("onError", error)
            }
        }

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isVpnAvailable" -> result.success(isLibboxLoaded())

                "requestVpnPermission" -> handleRequestPermission(result)

                "connect" -> {
                    val config = (call.arguments as? Map<*, *>)?.get("config") as? String
                    if (config.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "VPN configuration is required", null)
                    } else {
                        handleConnect(config, result)
                    }
                }

                "reloadConfig" -> {
                    val config = (call.arguments as? Map<*, *>)?.get("config") as? String
                    if (config.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "VPN configuration is required", null)
                    } else if (FetuVpnService.currentStatus != "connected") {
                        result.error("NOT_RUNNING", "VPN service is not running", null)
                    } else {
                        dispatchToService(FetuVpnService.ACTION_RELOAD, config)
                        result.success(null)
                    }
                }

                "disconnect" -> {
                    dispatchToService(FetuVpnService.ACTION_DISCONNECT, null)
                    result.success(null)
                }

                "getStatus" -> result.success(FetuVpnService.currentStatus)

                "getMetrics" -> result.success(FetuVpnService.currentMetricsMap())

                else -> result.notImplemented()
            }
        }
    }

    private fun isLibboxLoaded(): Boolean {
        return try {
            Libbox.touch()
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent == null) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null || pendingConnectResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "VPN permission dialog already active", null)
            return
        }
        pendingPermissionResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(prepareIntent, REQUEST_VPN_PERMISSION)
    }

    private fun handleConnect(config: String, result: MethodChannel.Result) {
        if (!isLibboxLoaded()) {
            result.error("VPN_CORE_UNAVAILABLE", "libbox native library is unavailable", null)
            return
        }
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent == null) {
            dispatchToService(FetuVpnService.ACTION_CONNECT, config)
            result.success(null)
            return
        }
        if (pendingPermissionResult != null || pendingConnectResult != null) {
            result.error("PERMISSION_IN_PROGRESS", "VPN permission dialog already active", null)
            return
        }
        pendingConnectConfig = config
        pendingConnectResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(prepareIntent, REQUEST_VPN_PERMISSION)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_VPN_PERMISSION) {
            val granted = resultCode == Activity.RESULT_OK

            pendingPermissionResult?.let { res ->
                pendingPermissionResult = null
                res.success(granted)
            }

            pendingConnectResult?.let { res ->
                val config = pendingConnectConfig
                pendingConnectResult = null
                pendingConnectConfig = null
                if (granted && !config.isNullOrBlank()) {
                    dispatchToService(FetuVpnService.ACTION_CONNECT, config)
                    res.success(null)
                } else {
                    res.error("VPN_PERMISSION_DENIED", "User denied VPN permission", null)
                }
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun dispatchToService(action: String, config: String?) {
        val intent = Intent(this, FetuVpnService::class.java).apply {
            this.action = action
            if (config != null) {
                putExtra(FetuVpnService.EXTRA_CONFIG, config)
            }
        }
        if (action == FetuVpnService.ACTION_CONNECT && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onDestroy() {
        if (channel != null) {
            FetuVpnService.onStatusChanged = null
            FetuVpnService.onMetricsUpdated = null
            FetuVpnService.onError = null
            channel = null
        }
        super.onDestroy()
    }

    private companion object {
        const val CHANNEL = "com.fetu.app/method_channel"
        const val REQUEST_VPN_PERMISSION = 4101
    }
}
