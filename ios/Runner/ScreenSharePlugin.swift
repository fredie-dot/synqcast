import Foundation
import Flutter
import ReplayKit
import AVFoundation

@available(iOS 11.0, *)
class ScreenSharePlugin: NSObject, FlutterPlugin, RPScreenRecorderDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var isRecording = false
    private var currentStreamId: String?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "synqcast_screen_share", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "synqcast_screen_share_events", binaryMessenger: registrar.messenger())
        let instance = ScreenSharePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        instance.methodChannel = channel
        instance.eventChannel = eventChannel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScreenShare":
            startScreenShare(call: call, result: result)
        case "stopScreenShare":
            stopScreenShare(result: result)
        case "isScreenShareSupported":
            checkSupport(result: result)
        case "requestScreenRecordingPermission":
            requestPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startScreenShare(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isRecording {
            result(FlutterError(code: "ALREADY_RECORDING", message: "Screen sharing is already active", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let width = args["width"] as? Int ?? 1920
        let height = args["height"] as? Int ?? 1080
        let frameRate = args["frameRate"] as? Int ?? 30
        let bitRate = args["bitrate"] as? Int ?? 6000000
        let includeAudio = args["includeAudio"] as? Bool ?? false
        
        let recorder = RPScreenRecorder.shared()
        recorder.delegate = self
        
        if recorder.isAvailable {
            recorder.startRecording { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        result(FlutterError(code: "START_ERROR", message: "Failed to start screen sharing", details: error.localizedDescription))
                    } else {
                        self?.isRecording = true
                        self?.currentStreamId = String(Date().timeIntervalSince1970)
                        
                        // Send event
                        self?.sendEvent(type: "recording_started", data: nil)
                        
                        result([
                            "success": true,
                            "streamId": self?.currentStreamId ?? "",
                            "filePath": "" // iOS doesn't provide direct file path
                        ])
                    }
                }
            }
        } else {
            result(FlutterError(code: "NOT_AVAILABLE", message: "Screen recording is not available", details: nil))
        }
    }
    
    private func stopScreenShare(result: @escaping FlutterResult) {
        if !isRecording {
            result(["success": true])
            return
        }
        
        let recorder = RPScreenRecorder.shared()
        recorder.stopRecording { [weak self] previewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "STOP_ERROR", message: "Failed to stop screen sharing", details: error.localizedDescription))
                } else {
                    self?.isRecording = false
                    self?.currentStreamId = nil
                    
                    // Send event
                    self?.sendEvent(type: "recording_stopped", data: nil)
                    
                    // Present preview controller if available
                    if let previewController = previewController {
                        // In a real app, you would present this controller
                        // For now, we'll just dismiss it
                        previewController.dismiss(animated: true)
                    }
                    
                    result(["success": true])
                }
            }
        }
    }
    
    private func checkSupport(result: @escaping FlutterResult) {
        let supported = RPScreenRecorder.shared().isAvailable
        result(["supported": supported])
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
        let recorder = RPScreenRecorder.shared()
        if recorder.isAvailable {
            result(["granted": true])
        } else {
            result(["granted": false])
        }
    }
    
    private func sendEvent(type: String, data: [String: Any]?) {
        let event: [String: Any] = [
            "type": type,
            "data": data ?? [:]
        ]
        eventSink?(event)
    }
    
    // MARK: - RPScreenRecorderDelegate
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewController: RPPreviewViewController?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                self?.sendEvent(type: "error", data: ["message": error.localizedDescription])
            } else {
                self?.sendEvent(type: "recording_stopped", data: nil)
            }
        }
    }
}

// MARK: - FlutterStreamHandler

@available(iOS 11.0, *)
extension ScreenSharePlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
