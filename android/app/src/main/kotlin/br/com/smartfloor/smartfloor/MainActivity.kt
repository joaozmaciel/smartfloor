package br.com.smartfloor.smartfloor

import android.Manifest
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(),
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    companion object {
        private const val METHOD_CHANNEL = "smartfloor/ar_measurement"
        private const val EVENT_CHANNEL = "smartfloor/ar_measurement/events"
        private const val VIEW_TYPE = "smartfloor/ar_measurement_view"
        private const val CAMERA_PERMISSION_REQUEST = 7294
    }

    @Volatile
    private var arSession: Session? = null
    @Volatile
    private var sessionActive = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var activeViewId: Int? = null
    private var activeView: ArMeasurementPlatformView? = null
    private var previousTrackingState: String? = null
    private var installRequested = false
    private var pendingCameraPermissionResult: MethodChannel.Result? = null

    val displayRotation: Int
        get() = windowManager.defaultDisplay.rotation

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).also { it.setMethodCallHandler(this) }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(this)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            VIEW_TYPE,
            ArMeasurementViewFactory(this),
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> checkAvailability(result)
            "requestCameraPermission" -> requestCameraPermission(result)
            "requestInstall" -> requestArCoreInstall(result)
            "start" -> startArSession(result)
            "capturePoint" -> {
                val view = activeView
                if (view == null) {
                    result.error("NO_AR_VIEW", "A visualização AR não está pronta.", null)
                } else {
                    view.requestCenterTap()
                    result.success(null)
                }
            }
            "pause" -> {
                pauseArSession()
                result.success(null)
            }
            "resume" -> {
                resumeArSession()
                result.success(null)
            }
            "stop" -> {
                stopArSession()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        val status = when (ArCoreApk.getInstance().checkAvailability(this)) {
            ArCoreApk.Availability.SUPPORTED_INSTALLED -> "supported"
            ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED,
            ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD -> "needsInstall"
            else -> "unsupported"
        }
        result.success(status)
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.CAMERA,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingCameraPermissionResult != null) {
            result.error(
                "PERMISSION_REQUEST_ACTIVE",
                "A solicitação de permissão da câmera já está aberta.",
                null,
            )
            return
        }
        pendingCameraPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST,
        )
    }

    private fun requestArCoreInstall(result: MethodChannel.Result) {
        try {
            val status = ArCoreApk.getInstance().requestInstall(this, !installRequested)
            if (status == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                installRequested = true
                result.success(false)
            } else {
                result.success(true)
            }
        } catch (error: UnavailableUserDeclinedInstallationException) {
            result.error("ARCORE_INSTALL_DECLINED", error.message, null)
        } catch (error: Exception) {
            result.error("ARCORE_INSTALL_FAILED", error.message, null)
        }
    }

    private fun startArSession(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.CAMERA,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                "CAMERA_PERMISSION_REQUIRED",
                "É necessário permitir o acesso à câmera.",
                null,
            )
            return
        }

        try {
            val installStatus = ArCoreApk.getInstance().requestInstall(this, false)
            if (installStatus != ArCoreApk.InstallStatus.INSTALLED) {
                result.error(
                    "ARCORE_INSTALL_REQUIRED",
                    "Instale ou atualize o Google Play Services para RA.",
                    null,
                )
                return
            }

            val session = arSession ?: Session(this).also { newSession ->
                val config = Config(newSession)
                if (newSession.isDepthModeSupported(Config.DepthMode.AUTOMATIC)) {
                    config.depthMode = Config.DepthMode.AUTOMATIC
                }
                config.focusMode = Config.FocusMode.AUTO
                newSession.configure(config)
                arSession = newSession
            }
            activeView?.setSession(session)
            resumeArSession()
            result.success(null)
        } catch (error: CameraNotAvailableException) {
            result.error("CAMERA_UNAVAILABLE", error.message, null)
        } catch (error: Exception) {
            result.error(
                "AR_SESSION_START_FAILED",
                error.message ?: "Não foi possível iniciar o ARCore.",
                null,
            )
        }
    }

    private fun resumeArSession() {
        val session = arSession ?: return
        if (sessionActive) return
        try {
            session.resume()
            sessionActive = true
            activeView?.resume()
        } catch (error: CameraNotAvailableException) {
            emitArEvent(
                mapOf(
                    "type" to "error",
                    "message" to "A câmera não está disponível para o ARCore.",
                ),
            )
        }
    }

    private fun pauseArSession() {
        if (!sessionActive) return
        activeView?.pause()
        arSession?.pause()
        sessionActive = false
    }

    private fun stopArSession() {
        pauseArSession()
        arSession?.close()
        arSession = null
        activeView?.setSession(null)
        previousTrackingState = null
    }

    fun registerView(viewId: Int, view: ArMeasurementPlatformView) {
        activeViewId = viewId
        activeView = view
        arSession?.let(view::setSession)
    }

    fun unregisterView(viewId: Int) {
        if (activeViewId != viewId) return
        activeViewId = null
        activeView = null
    }

    fun onArFrame(
        frame: Frame,
        width: Int,
        height: Int,
        capturePoint: Boolean,
    ) {
        val camera = frame.camera
        val trackingState = when (camera.trackingState) {
            TrackingState.TRACKING -> "tracking"
            TrackingState.PAUSED -> "paused"
            TrackingState.STOPPED -> "stopped"
        }
        if (trackingState != previousTrackingState) {
            previousTrackingState = trackingState
            emitArEvent(mapOf("type" to "tracking", "trackingState" to trackingState))
        }

        if (!capturePoint) return
        if (camera.trackingState != TrackingState.TRACKING) {
            emitArEvent(
                mapOf(
                    "type" to "tapFailed",
                    "message" to "O AR ainda está localizando a superfície. Mova o celular devagar.",
                ),
            )
            return
        }

        val x = width / 2f
        val y = height / 2f
        val hits = frame.hitTest(x, y)
        val hit = hits.firstOrNull { result ->
            val trackable = result.trackable
            trackable is Plane &&
                trackable.trackingState == TrackingState.TRACKING &&
                trackable.isPoseInPolygon(result.hitPose)
        } ?: hits.firstOrNull { it.trackable.trackingState == TrackingState.TRACKING }

        if (hit == null) {
            emitArEvent(
                mapOf(
                    "type" to "tapFailed",
                    "message" to "Não encontrei uma superfície. Aponte para o chão ou uma parede.",
                ),
            )
            return
        }

        val position = hit.hitPose.translation.map { it.toDouble() }
        emitArEvent(mapOf("type" to "point", "position" to position))
    }

    fun emitArEvent(event: Map<String, Any>) {
        mainHandler.post { eventSink?.success(event) }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    @Deprecated("Deprecated in Android")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CAMERA_PERMISSION_REQUEST) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingCameraPermissionResult?.success(granted)
        pendingCameraPermissionResult = null
    }

    override fun onResume() {
        super.onResume()
        resumeArSession()
    }

    override fun onPause() {
        pauseArSession()
        super.onPause()
    }

    override fun onDestroy() {
        stopArSession()
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
