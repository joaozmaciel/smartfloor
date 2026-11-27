package br.com.smartfloor.smartfloor

import android.content.Context
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class ArMeasurementViewFactory(
    private val activity: MainActivity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView = ArMeasurementPlatformView(context, viewId, activity)
}
