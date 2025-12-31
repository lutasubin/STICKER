package com.mobileai.stickerapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Entry activity that also registers the custom WhatsApp sticker plugin
 * packaged inside the app module.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the in-app plugin so the Dart MethodChannel can reach native code.
        flutterEngine.plugins.add(WhatsappStickersPlugin())
    }
}

