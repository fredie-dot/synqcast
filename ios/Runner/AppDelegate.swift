import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register custom plugins
    if #available(iOS 11.0, *) {
      ScreenSharePlugin.register(with: self.registrar(forPlugin: "ScreenSharePlugin")!)
    }
    RecordingPlugin.register(with: self.registrar(forPlugin: "RecordingPlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
