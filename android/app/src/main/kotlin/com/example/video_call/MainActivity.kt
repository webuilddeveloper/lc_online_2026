package td.webuild.lawyer

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pipChannel = "lc_online/pip"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pipChannel)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "enterPip" -> {
                    result.success(enterPipMode())
                }
                "isInPip" -> {
                    result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16))
                .build()
            enterPictureInPictureMode(params)
        } catch (_: Exception) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        methodChannel?.invokeMethod("onUserLeaveHint", null)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        }
        methodChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }
}
