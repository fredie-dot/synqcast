import Foundation
import Flutter
import AVFoundation
import Photos

class RecordingPlugin: NSObject, FlutterPlugin {
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var isRecording = false
    private var currentRecordingId: String?
    private var outputFile: URL?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "synqcast_recording", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "synqcast_recording_events", binaryMessenger: registrar.messenger())
        let instance = RecordingPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        instance.methodChannel = channel
        instance.eventChannel = eventChannel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            startRecording(call: call, result: result)
        case "stopRecording":
            stopRecording(result: result)
        case "getRecordings":
            getRecordings(result: result)
        case "deleteRecording":
            deleteRecording(call: call, result: result)
        case "shareRecording":
            shareRecording(call: call, result: result)
        case "requestRecordingPermission":
            requestPermission(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if isRecording {
            result(FlutterError(code: "ALREADY_RECORDING", message: "Recording is already active", details: nil))
            return
        }
        
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        let recordingId = args["recordingId"] as? String ?? "recording_\(Date().timeIntervalSince1970)"
        let roomName = args["roomName"] as? String
        let width = args["width"] as? Int ?? 1920
        let height = args["height"] as? Int ?? 1080
        let frameRate = args["frameRate"] as? Int ?? 30
        let bitRate = args["bitrate"] as? Int ?? 6000000
        let includeAudio = args["includeAudio"] as? Bool ?? true
        
        // Create output file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "synqcast_\(roomName ?? "recording")_\(Date().timeIntervalSince1970).mp4"
        outputFile = documentsPath.appendingPathComponent(fileName)
        
        guard let outputFile = outputFile else {
            result(FlutterError(code: "FILE_ERROR", message: "Failed to create output file", details: nil))
            return
        }
        
        // Check permissions
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startAVRecording(outputFile: outputFile, recordingId: recordingId, result: result)
                } else {
                    result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission denied", details: nil))
                }
            }
        }
    }
    
    private func startAVRecording(outputFile: URL, recordingId: String, result: @escaping FlutterResult) {
        // For iOS, we'll use a simplified approach since full screen recording requires ReplayKit
        // This is a placeholder implementation that would need to be expanded for full functionality
        
        isRecording = true
        currentRecordingId = recordingId
        
        // Send event
        sendEvent(type: "recording_started", data: nil)
        
        result([
            "success": true,
            "filePath": outputFile.path
        ])
    }
    
    private func stopRecording(result: @escaping FlutterResult) {
        if !isRecording {
            result(["success": true])
            return
        }
        
        isRecording = false
        currentRecordingId = nil
        
        // Send event
        sendEvent(type: "recording_stopped", data: nil)
        
        result(["success": true])
    }
    
    private func getRecordings(result: @escaping FlutterResult) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var recordings: [[String: Any]] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            for file in files {
                if file.lastPathComponent.hasPrefix("synqcast_") && file.pathExtension == "mp4" {
                    let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    
                    let recording: [String: Any] = [
                        "filename": file.lastPathComponent,
                        "filePath": file.path,
                        "size": fileSize,
                        "startTime": nil,
                        "endTime": nil,
                        "duration": 0,
                        "roomName": file.lastPathComponent.replacingOccurrences(of: "synqcast_", with: "").replacingOccurrences(of: ".mp4", with: "")
                    ]
                    recordings.append(recording)
                }
            }
        } catch {
            print("Error getting recordings: \(error)")
        }
        
        result([
            "success": true,
            "recordings": recordings
        ])
    }
    
    private func deleteRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filename = args["filename"] as? String else {
            result(FlutterError(code: "INVALID_FILENAME", message: "Filename is required", details: nil))
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            result(["success": true])
        } catch {
            result(FlutterError(code: "DELETE_ERROR", message: "Failed to delete recording", details: error.localizedDescription))
        }
    }
    
    private func shareRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filename = args["filename"] as? String else {
            result(FlutterError(code: "INVALID_FILENAME", message: "Filename is required", details: nil))
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // In a real implementation, this would use UIActivityViewController to share the file
            // For now, we'll just return success
            result(["success": true])
        } else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Recording file not found", details: nil))
        }
    }
    
    private func requestPermission(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                result(["granted": granted])
            }
        }
    }
    
    private func sendEvent(type: String, data: [String: Any]?) {
        let event: [String: Any] = [
            "type": type,
            "data": data ?? [:]
        ]
        eventSink?(event)
    }
}

// MARK: - FlutterStreamHandler

extension RecordingPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
