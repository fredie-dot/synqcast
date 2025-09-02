import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/quality_settings.dart';

class MobileScreenShareService {
  static const MethodChannel _channel = MethodChannel('synqcast_screen_share');
  static const EventChannel _eventChannel = EventChannel('synqcast_screen_share_events');
  
  static StreamSubscription? _eventSubscription;
  static bool _isSharing = false;
  static String? _currentStreamId;

  /// Start screen sharing on mobile platforms
  static Future<dynamic> startScreenShare({
    required QualitySettings quality,
    required bool includeAudio,
  }) async {
    try {
      debugPrint('Starting mobile screen share with quality: ${quality.name}');
      
      // Request screen recording permission
      final hasPermission = await _requestScreenRecordingPermission();
      if (!hasPermission) {
        throw Exception('Screen recording permission denied');
      }

      // Start screen recording
      final result = await _channel.invokeMethod('startScreenShare', {
        'width': quality.width,
        'height': quality.height,
        'frameRate': quality.frameRate,
        'bitrate': quality.bitrate,
        'includeAudio': includeAudio,
      });

      if (result['success'] == true) {
        _isSharing = true;
        _currentStreamId = result['streamId'];
        
        // Listen for events
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          (event) => _handleScreenShareEvent(event),
          onError: (error) => debugPrint('Screen share event error: $error'),
        );

        debugPrint('Mobile screen share started successfully');
        return result;
      } else {
        throw Exception('Failed to start screen share: ${result['error']}');
      }
    } catch (e) {
      debugPrint('Error starting mobile screen share: $e');
      rethrow;
    }
  }

  /// Stop screen sharing
  static Future<void> stopScreenShare(dynamic stream) async {
    try {
      if (!_isSharing) return;

      debugPrint('Stopping mobile screen share');
      
      await _channel.invokeMethod('stopScreenShare', {
        'streamId': _currentStreamId,
      });

      _isSharing = false;
      _currentStreamId = null;
      _eventSubscription?.cancel();
      _eventSubscription = null;

      debugPrint('Mobile screen share stopped successfully');
    } catch (e) {
      debugPrint('Error stopping mobile screen share: $e');
      rethrow;
    }
  }

  /// Check if screen sharing is supported on this platform
  static Future<bool> isSupported() async {
    try {
      if (Platform.isAndroid) {
        // Check Android API level and permissions
        final result = await _channel.invokeMethod('isScreenShareSupported');
        return result['supported'] == true;
      } else if (Platform.isIOS) {
        // Check iOS version and capabilities
        final result = await _channel.invokeMethod('isScreenShareSupported');
        return result['supported'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking screen share support: $e');
      return false;
    }
  }

  /// Request screen recording permission
  static Future<bool> _requestScreenRecordingPermission() async {
    try {
      final result = await _channel.invokeMethod('requestScreenRecordingPermission');
      return result['granted'] == true;
    } catch (e) {
      debugPrint('Error requesting screen recording permission: $e');
      return false;
    }
  }

  /// Handle screen share events from native platform
  static void _handleScreenShareEvent(dynamic event) {
    debugPrint('Screen share event: $event');
    
    switch (event['type']) {
      case 'permission_denied':
        _isSharing = false;
        break;
      case 'recording_started':
        debugPrint('Screen recording started');
        break;
      case 'recording_stopped':
        _isSharing = false;
        debugPrint('Screen recording stopped');
        break;
      case 'error':
        debugPrint('Screen share error: ${event['message']}');
        _isSharing = false;
        break;
    }
  }

  /// Get current screen share status
  static bool get isSharing => _isSharing;

  /// Get current stream ID
  static String? get currentStreamId => _currentStreamId;

  /// Dispose resources
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _isSharing = false;
    _currentStreamId = null;
  }
}
