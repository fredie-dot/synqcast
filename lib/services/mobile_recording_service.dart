import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/quality_settings.dart';

class MobileRecordingService {
  static const MethodChannel _channel = MethodChannel('synqcast_recording');
  static const EventChannel _eventChannel = EventChannel('synqcast_recording_events');
  
  static StreamSubscription? _eventSubscription;
  static StreamController<RecordingStatus>? _statusController;
  static bool _isRecording = false;
  static String? _currentRecordingId;
  static DateTime? _recordingStartTime;
  static String? _currentFilePath;

  /// Start recording on mobile platforms
  static Future<bool> startRecording({
    required dynamic mediaStream,
    required QualitySettings quality,
    String? roomName,
  }) async {
    try {
      if (_isRecording) {
        throw Exception('Recording already in progress');
      }

      debugPrint('Starting mobile recording with quality: ${quality.name}');
      
      // Request recording permission
      final hasPermission = await _requestRecordingPermission();
      if (!hasPermission) {
        throw Exception('Recording permission denied');
      }

      _currentRecordingId = 'recording_${DateTime.now().millisecondsSinceEpoch}';
      _recordingStartTime = DateTime.now();
      _statusController = StreamController<RecordingStatus>.broadcast();

      // Start recording
      final result = await _channel.invokeMethod('startRecording', {
        'recordingId': _currentRecordingId,
        'roomName': roomName,
        'width': quality.width,
        'height': quality.height,
        'frameRate': quality.frameRate,
        'bitrate': quality.bitrate,
        'includeAudio': true,
      });

      if (result['success'] == true) {
        _isRecording = true;
        _currentFilePath = result['filePath'];
        
        // Listen for recording events
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          (event) => _handleRecordingEvent(event),
          onError: (error) => debugPrint('Recording event error: $error'),
        );

        _statusController?.add(RecordingStatus(
          isRecording: true,
          recordingId: _currentRecordingId,
          startTime: _recordingStartTime,
        ));

        debugPrint('Mobile recording started successfully');
        return true;
      } else {
        throw Exception('Failed to start recording: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error starting mobile recording: $e');
      _statusController?.add(RecordingStatus(
        isRecording: false,
        error: 'Failed to start recording: $e',
      ));
      return false;
    }
  }

  /// Stop recording
  static Future<void> stopRecording() async {
    if (!_isRecording || _currentRecordingId == null) {
      return;
    }

    try {
      debugPrint('Stopping mobile recording');
      
      await _channel.invokeMethod('stopRecording', {
        'recordingId': _currentRecordingId,
      });

      _isRecording = false;
      
      _statusController?.add(RecordingStatus(
        isRecording: false,
        recordingId: _currentRecordingId,
        startTime: _recordingStartTime,
        endTime: DateTime.now(),
      ));

      debugPrint('Mobile recording stopped successfully');
    } catch (e) {
      debugPrint('Error stopping mobile recording: $e');
      _statusController?.add(RecordingStatus(
        isRecording: false,
        error: 'Failed to stop recording: $e',
      ));
    }
  }

  /// Get recording status stream
  static Stream<RecordingStatus>? get statusStream => _statusController?.stream;

  /// Get current recording status
  static bool get isRecording => _isRecording;

  /// Get current recording ID
  static String? get currentRecordingId => _currentRecordingId;

  /// Get current recording file path
  static String? get currentFilePath => _currentFilePath;

  /// Get all recordings
  static Future<List<RecordingMetadata>> getRecordings() async {
    try {
      final result = await _channel.invokeMethod('getRecordings');
      if (result['success'] == true) {
        final recordings = result['recordings'] as List;
        return recordings.map((r) => RecordingMetadata.fromMap(r)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting recordings: $e');
      return [];
    }
  }

  /// Delete a recording
  static Future<bool> deleteRecording(String filename) async {
    try {
      final result = await _channel.invokeMethod('deleteRecording', {
        'filename': filename,
      });
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  /// Share a recording
  static Future<bool> shareRecording(String filename) async {
    try {
      final result = await _channel.invokeMethod('shareRecording', {
        'filename': filename,
      });
      return result['success'] == true;
    } catch (e) {
      debugPrint('Error sharing recording: $e');
      return false;
    }
  }

  /// Request recording permission
  static Future<bool> _requestRecordingPermission() async {
    try {
      final result = await _channel.invokeMethod('requestRecordingPermission');
      return result['granted'] == true;
    } catch (e) {
      debugPrint('Error requesting recording permission: $e');
      return false;
    }
  }

  /// Handle recording events from native platform
  static void _handleRecordingEvent(dynamic event) {
    debugPrint('Recording event: $event');
    
    switch (event['type']) {
      case 'recording_started':
        debugPrint('Recording started');
        break;
      case 'recording_stopped':
        _isRecording = false;
        debugPrint('Recording stopped');
        break;
      case 'recording_saved':
        debugPrint('Recording saved: ${event['filePath']}');
        _currentFilePath = event['filePath'];
        break;
      case 'error':
        debugPrint('Recording error: ${event['message']}');
        _isRecording = false;
        _statusController?.add(RecordingStatus(
          isRecording: false,
          error: event['message'],
        ));
        break;
    }
  }

  /// Dispose resources
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _statusController?.close();
    _statusController = null;
    _isRecording = false;
    _currentRecordingId = null;
    _currentFilePath = null;
  }
}

class RecordingStatus {
  final bool isRecording;
  final String? recordingId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? error;

  RecordingStatus({
    required this.isRecording,
    this.recordingId,
    this.startTime,
    this.endTime,
    this.error,
  });
}

class RecordingMetadata {
  final String filename;
  final String? roomName;
  final DateTime? startTime;
  final DateTime? endTime;
  final int duration;
  final int size;
  final String filePath;

  RecordingMetadata({
    required this.filename,
    this.roomName,
    this.startTime,
    this.endTime,
    required this.duration,
    required this.size,
    required this.filePath,
  });

  factory RecordingMetadata.fromMap(Map<String, dynamic> map) {
    return RecordingMetadata(
      filename: map['filename'] ?? '',
      roomName: map['roomName'],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: map['duration'] ?? 0,
      size: map['size'] ?? 0,
      filePath: map['filePath'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filename': filename,
      'roomName': roomName,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'size': size,
      'filePath': filePath,
    };
  }
}
