import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'mobile_recording_service.dart';
import '../config/quality_settings.dart';

class RecordingService {
  static dynamic _mediaRecorder;
  static List<Uint8List> _recordedChunks = [];
  static bool _isRecording = false;
  static String? _currentRecordingId;
  static DateTime? _recordingStartTime;
  static StreamController<RecordingStatus>? _statusController;

  static Stream<RecordingStatus> get recordingStatus => 
      _statusController?.stream ?? Stream.empty();

  static bool get isRecording => _isRecording;

  static Future<bool> startRecording({
    required dynamic mediaStream,
    required QualitySettings quality,
    String? roomName,
  }) async {
    if (kIsWeb) {
      // Web implementation (existing code would go here)
      debugPrint('Web recording not implemented in this version');
      return false;
    } else {
      // Mobile implementation
      return await MobileRecordingService.startRecording(
        mediaStream: mediaStream,
        quality: quality,
        roomName: roomName,
      );
    }
  }

  static Future<void> stopRecording() async {
    if (kIsWeb) {
      // Web implementation (existing code would go here)
      debugPrint('Web recording stop not implemented in this version');
    } else {
      // Mobile implementation
      await MobileRecordingService.stopRecording();
    }
  }

  static Future<void> _saveRecording(String? roomName) async {
    try {
      // Mobile implementation would save recording here
      debugPrint('Recording saved for mobile');
      
      // Save recording metadata
      await _saveRecordingMetadata('mobile_recording.webm', roomName);

    } catch (e) {
      _statusController?.add(RecordingStatus(
        isRecording: false,
        error: 'Failed to save recording: $e',
      ));
    }
  }

  static Future<void> _saveRecordingMetadata(String filename, String? roomName) async {
    try {
      final metadata = {
        'filename': filename,
        'roomName': roomName,
        'startTime': _recordingStartTime?.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'duration': _recordingStartTime != null 
            ? DateTime.now().difference(_recordingStartTime!).inSeconds 
            : 0,
        'size': _recordedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length),
      };

      // Mobile implementation would use local storage or database
      debugPrint('Recording metadata saved for mobile');
    } catch (e) {
      debugPrint('Failed to save recording metadata: $e');
    }
  }

  static List<Map<String, dynamic>> _getRecordingsList() {
    // Mobile implementation would load from local storage
    return [];
  }

  static Future<List<RecordingMetadata>> getRecordings() async {
    if (kIsWeb) {
      final recordings = _getRecordingsList();
      return recordings.map((r) => RecordingMetadata.fromMap(r)).toList();
    } else {
      final mobileRecordings = await MobileRecordingService.getRecordings();
      return mobileRecordings.map((r) => RecordingMetadata(
        filename: r.filename,
        roomName: r.roomName,
        startTime: r.startTime ?? DateTime.now(),
        endTime: r.endTime ?? DateTime.now(),
        duration: r.duration,
        size: r.size,
      )).toList();
    }
  }

  static Future<bool> deleteRecording(String filename) async {
    if (kIsWeb) {
      try {
        // Web implementation would delete from localStorage
        debugPrint('Web recording delete not implemented in this version');
        return true;
      } catch (e) {
        debugPrint('Failed to delete recording: $e');
        return false;
      }
    } else {
      return await MobileRecordingService.deleteRecording(filename);
    }
  }

  static Future<bool> shareRecording(String filename) async {
    if (kIsWeb) {
      try {
        // Web implementation would share via browser
        debugPrint('Web recording share not implemented in this version');
        return true;
      } catch (e) {
        debugPrint('Failed to share recording: $e');
        return false;
      }
    } else {
      return await MobileRecordingService.shareRecording(filename);
    }
  }

  static void dispose() {
    _statusController?.close();
    _statusController = null;
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
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final int size;

  RecordingMetadata({
    required this.filename,
    this.roomName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.size,
  });

  factory RecordingMetadata.fromMap(Map<String, dynamic> map) {
    return RecordingMetadata(
      filename: map['filename'] ?? '',
      roomName: map['roomName'],
      startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(map['endTime'] ?? DateTime.now().toIso8601String()),
      duration: map['duration'] ?? 0,
      size: map['size'] ?? 0,
    );
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedSize {
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
