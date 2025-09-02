import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../config/livekit_config.dart';
import '../config/quality_settings.dart';
import 'permission_service.dart';

class RoomService {
  Room? _currentRoom;
  Room? get currentRoom => _currentRoom;
  
  Stream<Room?> get roomStream => Stream.value(_currentRoom);

  Future<Room> createRoom(String roomName, String participantName, {QualitySettings? quality, String? roomCode}) async {
    try {
      debugPrint('Creating room: $roomName with participant: $participantName');
      
      // Request permissions
      await _requestPermissions();
      debugPrint('Permissions granted');
      
      // Use provided room code or generate one
      final finalRoomCode = roomCode ?? _generateRoomCode();
      
      // Create room token using room code
      final token = await _generateToken(finalRoomCode, participantName);
      debugPrint('Token generated successfully');
      
      // Connect to room with quality settings
      final room = Room();
      debugPrint('Connecting to LiveKit server: ${LiveKitConfig.serverUrl}');
      
      // Apply quality settings if provided
      if (quality != null) {
        debugPrint('Applying quality settings: ${quality.name} (${quality.width}x${quality.height} @ ${quality.frameRate}fps)');
      }
      
      await room.connect(LiveKitConfig.serverUrl, token);
      print('Connected to room successfully');
      
      _currentRoom = room;
      
      return room;
    } catch (e) {
      debugPrint('Error creating room: $e');
      throw Exception('Failed to create room: $e');
    }
  }

  String _generateRoomCode() {
    // Generate a secure 8-character room code with mixed characters
    final random = DateTime.now().millisecondsSinceEpoch;
    final random2 = DateTime.now().microsecondsSinceEpoch;
    
    // Create a more random pattern: 2 letters + 2 numbers + 2 letters + 2 numbers
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final numbers = '0123456789';
    
    final code = StringBuffer();
    
    // First 2 letters
    for (int i = 0; i < 2; i++) {
      final index = (random + i * 7) % letters.length;
      code.write(letters[index]);
    }
    
    // Next 2 numbers
    for (int i = 0; i < 2; i++) {
      final index = (random2 + i * 3) % numbers.length;
      code.write(numbers[index]);
    }
    
    // Next 2 letters
    for (int i = 0; i < 2; i++) {
      final index = (random + random2 + i * 11) % letters.length;
      code.write(letters[index]);
    }
    
    // Last 2 numbers
    for (int i = 0; i < 2; i++) {
      final index = (random * random2 + i * 5) % numbers.length;
      code.write(numbers[index]);
    }
    
    return code.toString();
  }

  Future<Room> joinRoom(String roomCode, String participantName) async {
    try {
      debugPrint('Joining room: $roomCode with participant: $participantName');
      
      // Request permissions
              await _requestPermissions();
        debugPrint('Permissions granted');
      
              // Create room token using the room code as room name
        final token = await _generateToken(roomCode, participantName);
        debugPrint('Token generated successfully');
      
              // Connect to room
        final room = Room();
        debugPrint('Connecting to LiveKit server: ${LiveKitConfig.serverUrl}');
        await room.connect(LiveKitConfig.serverUrl, token);
        debugPrint('Connected to room successfully');
      
      _currentRoom = room;
      
      return room;
    } catch (e) {
              debugPrint('Error joining room: $e');
      throw Exception('Failed to join room: $e');
    }
  }

  Future<void> leaveRoom() async {
    if (_currentRoom != null) {
      await _currentRoom!.disconnect();
      _currentRoom = null;
    }
  }

  Future<void> _requestPermissions() async {
    // Use the centralized permission service
    final granted = await PermissionService.requestAllPermissions();
    if (!granted && !kIsWeb) {
      throw Exception('Required permissions not granted');
    }
  }

  Future<String> _generateToken(String roomName, String participantName) async {
    try {
      final response = await http.post(
        Uri.parse('${LiveKitConfig.tokenServerUrl}/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'roomName': roomName,
          'participantName': participantName,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token'];
      } else {
        throw Exception('Failed to generate token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating token: $e');
      throw Exception('Failed to generate token: $e');
    }
  }

  Future<void> toggleScreenShare({QualitySettings? quality}) async {
    if (_currentRoom?.localParticipant != null) {
              final isEnabled = _currentRoom!.localParticipant!.isScreenShareEnabled == true;
      
      if (!isEnabled) {
        // Start screen sharing with quality settings
        debugPrint('Starting screen share with quality: ${quality?.name ?? 'default'}');
        await _currentRoom!.localParticipant!.setScreenShareEnabled(true);
        
        // Apply quality constraints if provided
        if (quality != null && kIsWeb) {
          debugPrint('Applying screen share quality: ${quality.width}x${quality.height} @ ${quality.frameRate}fps');
          // Note: Quality constraints are typically applied when getting the media stream
          // This would be handled in the screen selection dialog
        }
      } else {
        // Stop screen sharing
        debugPrint('Stopping screen share');
        await _currentRoom!.localParticipant!.setScreenShareEnabled(false);
      }
    }
  }

  Future<void> toggleAudio() async {
    if (_currentRoom?.localParticipant != null) {
      final isEnabled = (_currentRoom!.localParticipant!.isMicrophoneEnabled ?? false) == true;
      await _currentRoom!.localParticipant!.setMicrophoneEnabled(!isEnabled);
    }
  }

  Future<void> toggleVideo() async {
    if (_currentRoom?.localParticipant != null) {
      final isEnabled = (_currentRoom!.localParticipant!.isCameraEnabled ?? false) == true;
      await _currentRoom!.localParticipant!.setCameraEnabled(!isEnabled);
    }
  }

  void dispose() {
    leaveRoom();
  }
}
