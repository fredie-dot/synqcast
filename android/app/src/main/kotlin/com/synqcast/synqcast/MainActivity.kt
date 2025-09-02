package com.synqcast.synqcast

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register custom plugins
        flutterEngine.plugins.add(ScreenSharePlugin())
        flutterEngine.plugins.add(RecordingPlugin())
    }
}
