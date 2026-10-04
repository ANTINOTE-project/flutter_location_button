package fr.antinote.flutter_location_button

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.permissionui.LocationButtonClient
import android.app.permissionui.LocationButtonProviderFactory
import android.app.permissionui.LocationButtonRequest
import android.app.permissionui.LocationButtonSession
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Binder
import android.os.Build
import android.util.Log
import android.view.SurfaceControlViewHost
import android.view.SurfaceView
import android.view.View
import androidx.annotation.ChecksSdkIntAtLeast
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.locationbutton.R
import fr.antinote.flutter_location_button.LocationButtonTextType.NONE
import fr.antinote.flutter_location_button.LocationButtonTextType.NEAR_MY_PRECISE_LOCATION
import fr.antinote.flutter_location_button.LocationButtonTextType.NEAR_YOUR_PRECISE_LOCATION
import fr.antinote.flutter_location_button.LocationButtonTextType.PRECISE_LOCATION
import fr.antinote.flutter_location_button.LocationButtonTextType.SHARE_PRECISE_LOCATION
import fr.antinote.flutter_location_button.LocationButtonTextType.USE_PRECISE_LOCATION
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
fun LocationButtonTextType.toTextTypeId() = when (this) {
    NONE -> LocationButtonSession.TEXT_TYPE_NONE
    PRECISE_LOCATION -> LocationButtonSession.TEXT_TYPE_PRECISE_LOCATION
    USE_PRECISE_LOCATION -> LocationButtonSession.TEXT_TYPE_USE_PRECISE_LOCATION
    SHARE_PRECISE_LOCATION -> LocationButtonSession.TEXT_TYPE_SHARE_PRECISE_LOCATION
    NEAR_MY_PRECISE_LOCATION -> LocationButtonSession.TEXT_TYPE_NEAR_MY_PRECISE_LOCATION
    NEAR_YOUR_PRECISE_LOCATION -> LocationButtonSession.TEXT_TYPE_NEAR_YOUR_PRECISE_LOCATION
}

@RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
fun RawLocationButtonStyle.toRequest(configuration: Configuration) =
    LocationButtonRequest.Builder(width.toInt(), height.toInt(), configuration).run {
        if (leftPadding != null) setPaddingLeft(leftPadding.toInt())
        if (topPadding != null) setPaddingTop(topPadding.toInt())
        if (rightPadding != null) setPaddingRight(rightPadding.toInt())
        if (bottomPadding != null) setPaddingBottom(bottomPadding.toInt())

        if (backgroundColor != null) setBackgroundColor(backgroundColor.toInt())

        if (strokeColor != null) setStrokeColor(strokeColor.toInt())
        setStrokeWidth(strokeWidth.toInt())

        if (cornerRadius != null) setCornerRadius(cornerRadius.toFloat())
        if (pressedCornerRadius != null) setPressedCornerRadius(pressedCornerRadius.toFloat())

        if (iconTintColor != null) setIconTint(iconTintColor.toInt())

        setTextType(textType.toTextTypeId())
        if (textColor != null) setTextColor(textColor.toInt())

        build()
    }

@RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
fun LocationButtonSession.update(
    oldStyle: RawLocationButtonStyle, newStyle: RawLocationButtonStyle
) {
    if (oldStyle.width != newStyle.width || oldStyle.height != newStyle.height) {
        resize(newStyle.width.toInt(), newStyle.height.toInt())
    }

    if (oldStyle.leftPadding != newStyle.leftPadding
        || oldStyle.topPadding != newStyle.topPadding
        || oldStyle.rightPadding != newStyle.rightPadding
        || oldStyle.bottomPadding != newStyle.bottomPadding
    ) {
        setPadding(
            newStyle.leftPadding?.toInt() ?: oldStyle.leftPadding?.toInt() ?: 4,
            newStyle.topPadding?.toInt() ?: oldStyle.topPadding?.toInt() ?: 4,
            newStyle.rightPadding?.toInt() ?: oldStyle.rightPadding?.toInt() ?: 4,
            newStyle.bottomPadding?.toInt() ?: oldStyle.bottomPadding?.toInt() ?: 4
        )
    }

    if (oldStyle.cornerRadius != newStyle.cornerRadius) setCornerRadius(
        newStyle.cornerRadius?.toFloat() ?: oldStyle.cornerRadius!!.toFloat()
    )

    if (oldStyle.pressedCornerRadius != newStyle.pressedCornerRadius) setPressedCornerRadius(
        newStyle.pressedCornerRadius?.toFloat() ?: oldStyle.pressedCornerRadius!!.toFloat()
    )

    if (oldStyle.textColor != newStyle.textColor) setTextColor(
        newStyle.textColor?.toInt() ?: oldStyle.textColor!!.toInt()
    )
    if (oldStyle.backgroundColor != newStyle.backgroundColor) setBackgroundColor(
        newStyle.backgroundColor?.toInt() ?: oldStyle.backgroundColor!!.toInt()
    )
    if (oldStyle.iconTintColor != newStyle.iconTintColor) setIconTint(
        newStyle.iconTintColor?.toInt() ?: oldStyle.iconTintColor!!.toInt()
    )

    if (oldStyle.textType != newStyle.textType) setTextType(newStyle.textType.toTextTypeId())

    if (oldStyle.strokeColor != newStyle.strokeColor) setStrokeColor(
        newStyle.strokeColor?.toInt() ?: oldStyle.strokeColor!!.toInt()
    )
    if (oldStyle.strokeWidth != newStyle.strokeWidth) setStrokeWidth(newStyle.strokeWidth.toInt())
}

class FlutterLocationButtonPlugin : FlutterPlugin, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener, LocationButtonApi {
    companion object {
        private const val TAG = "FlutterLocationButton"
        private const val VIEW_TYPE = "location_button"

        private val LISTENED_LOCATION_PERMISSIONS = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION
        )
    }

    private var activity: Activity? = null
    val scope = CoroutineScope(Dispatchers.Main)
    private var callback: LocationButtonCallback? = null

    @ChecksSdkIntAtLeast(api = Build.VERSION_CODES.CINNAMON_BUN)
    fun isSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.CINNAMON_BUN
    }

    val sessions: MutableMap<Long, LocationButtonSession> = mutableMapOf()

    override suspend fun createSession(
        sessionHandle: Long, style: RawLocationButtonStyle
    ): Boolean {
        if (!isSupported()) return false

        val token = Binder(sessionHandle.toString())
        val completable = CompletableDeferred<LocationButtonSession?>()

        LocationButtonProviderFactory.create(activity!!).openSession(
            activity!!,
            token,
            activity!!.display.displayId,
            style.toRequest(activity!!.resources.configuration),
            activity!!.mainExecutor,
            object : LocationButtonClient {
                override fun onPermissionResult(isGranted: Boolean) {
                    Log.i(TAG, "Permission result got returned! $isGranted")

                    scope.launch {
                        callback?.permissionResult(sessionHandle, isGranted)
                    }
                }

                override fun onSessionError(cause: Throwable) {
                    Log.e(TAG, "Location button session exited unexpectedly.", cause)

                    if (!completable.complete(null)) {
                        scope.launch {
                            callback?.sessionDead(sessionHandle)
                            sessions.remove(sessionHandle)
                        }
                    }
                }

                override fun onSessionOpened(session: LocationButtonSession) {
                    completable.complete(session)
                }
            })

        val session: LocationButtonSession = completable.await() ?: return false

        sessions[sessionHandle] = session

        return true
    }

    @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
    override fun updateButton(
        sessionHandle: Long, oldStyle: RawLocationButtonStyle, newStyle: RawLocationButtonStyle
    ) {
        val session = sessions[sessionHandle] ?: return
        session.update(oldStyle, newStyle)
    }

    @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
    override fun closeSession(sessionHandle: Long) {
        val session = sessions.remove(sessionHandle)
        session?.close()
    }

    val waitingPermissionResults = mutableMapOf<Long, MutableList<(Result<Boolean>) -> Unit>>()

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String?>, grantResults: IntArray
    ): Boolean {
        Log.i(
            TAG,
            "Got a request permission result with code $requestCode "
                    + "(${grantResults.contentToString()} for ${permissions.contentToString()})"
        )

        if (!waitingPermissionResults.containsKey(requestCode.toLong()) || permissions.any {
                !LISTENED_LOCATION_PERMISSIONS.contains(
                    it
                )
            }) {
            return false
        }

        val remainingList = waitingPermissionResults[requestCode.toLong()]!!
        val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }

        while (remainingList.isNotEmpty()) {
            val callback = remainingList.removeAt(0)
            callback(Result.success(granted))
        }

        return true
    }

    override fun requestPermission(
        sessionHandle: Long, callback: (Result<Boolean>) -> Unit
    ) {
        if (ContextCompat.checkSelfPermission(
                activity!!.applicationContext, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            callback(Result.success(true))
            return
        }

        waitingPermissionResults.putIfAbsent(sessionHandle, mutableListOf())
        waitingPermissionResults[sessionHandle]!!.add(callback)

        ActivityCompat.requestPermissions(
            activity!!, arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION
            ), sessionHandle.toInt()
        )
    }

    override fun fetchLocalization(): Map<LocationButtonTextType, String> = localizations()

    @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
    suspend fun cleanupSessions() {
        for (key in sessions.keys) {
            sessions.remove(key)?.close()

            if (callback != null) {
                callback!!.sessionDead(key)
            }
        }
    }

    inner class LocationButtonNativeViewFactory :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(
            context: Context, viewId: Int, args: Any?
        ): PlatformView {
            if (args == null || args !is Int) {
                Log.e(TAG, "Session handle is: $args (${args?.javaClass})")
                throw IllegalArgumentException(
                    "A session handle is required to create a location " + "button."
                )
            }

            val handle = args.toLong()

            val session = sessions[handle] ?: throw IllegalStateException(
                "Tried to create a native location button for a session that does not " + "exist."
            )

            return object : PlatformView {
                @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
                private val surfaceView: SurfaceView = SurfaceView(context).apply {
                    compositionOrder = 1

                    val packageCopy = SurfaceControlViewHost.SurfacePackage(session.surfacePackage)
                    setChildSurfacePackage(packageCopy)
                }

                @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
                override fun getView(): View = surfaceView

                @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
                override fun dispose() {
                    surfaceView.clearChildSurfacePackage()
                }
            }
        }

    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE, LocationButtonNativeViewFactory()
        )

        LocationButtonApi.setUp(flutterPluginBinding.binaryMessenger, this)
        callback = LocationButtonCallback(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (isSupported()) {
            scope.launch {
                cleanupSessions()
            }
        }
        callback = null
    }

    @SuppressLint("PrivateResource")
    private fun localizations() = LocationButtonTextType.entries.associate {
        it to activity!!.getString(
            when (it) {
                PRECISE_LOCATION -> R.string.location_button_precise_location
                USE_PRECISE_LOCATION -> R.string.location_button_use_precise_location
                SHARE_PRECISE_LOCATION -> R.string.location_button_share_precise_location
                NEAR_MY_PRECISE_LOCATION -> R.string.location_button_near_my_precise_location
                NEAR_YOUR_PRECISE_LOCATION -> R.string.location_button_near_your_precise_location

                // This is for none, it will disappear on the flutter side.
                else -> R.string.location_button_precise_location
            }
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity

        binding.addRequestPermissionsResultListener(this)

        scope.launch {
            callback?.newLocalizations(localizations())
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null

        if (isSupported()) {
            scope.launch {
                cleanupSessions()
            }
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity

        binding.addRequestPermissionsResultListener(this)

        @SuppressLint("PrivateResource") scope.launch {
            callback?.newLocalizations(localizations())
        }

        if (isSupported()) {
            for (session in sessions.values) {
                session.changeConfiguration(binding.activity.resources.configuration)
            }
        }
    }

    override fun onDetachedFromActivity() {
        activity = null

        if (isSupported()) {
            scope.launch {
                cleanupSessions()
            }
        }
    }
}