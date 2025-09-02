import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../services/settings_service.dart';
import '../services/recording_service.dart';
import '../services/screen_share_service.dart';
import '../config/quality_settings.dart';
import '../widgets/screen_selection_dialog.dart';

import 'dart:async';

class RoomScreen extends StatefulWidget {
  final Room? room;
  final RoomModel? roomModel;

  const RoomScreen({
    super.key,
    this.room,
    this.roomModel,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  Room? _room;
  bool _isScreenSharing = false;
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = true;
  bool _isRecording = false;
  List<Participant> _participants = [];
  String _roomCode = '';
  QualitySettings? _selectedQuality;
  StreamSubscription<RecordingStatus>? _recordingSubscription;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    
    // Get room model from arguments if not provided directly
    if (widget.roomModel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is RoomModel) {
          setState(() {
            _roomCode = args.inviteCode ?? _generateRoomCode();
          });
        } else {
          setState(() {
            _roomCode = _generateRoomCode();
          });
        }
      });
    } else {
      _roomCode = widget.roomModel!.inviteCode ?? _generateRoomCode();
    }
    
    _setupRoom();
    _loadQualitySettings();
    _setupRecordingListener();
  }

  Future<void> _loadQualitySettings() async {
    final settings = await SettingsService.getInstance();
    final quality = await settings.getSelectedQuality();
    setState(() => _selectedQuality = quality);
  }

  void _setupRecordingListener() {
    _recordingSubscription = RecordingService.recordingStatus.listen((status) {
      if (mounted) {
        setState(() => _isRecording = status.isRecording);
        
        if (status.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (status.isRecording) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording started'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (status.endTime != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  String _generateRoomCode() {
    // Generate a secure 8-character room code with mixed characters
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
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

  void _setupRoom() {
    if (_room != null) {
      _room!.addListener(_onRoomUpdate);
      _updateParticipants();
      
              // Initialize local participant state
        if (_room!.localParticipant != null) {
          _isAudioEnabled = _room!.localParticipant!.isMicrophoneEnabled == true;
          _isVideoEnabled = _room!.localParticipant!.isCameraEnabled == true;
          _isScreenSharing = _room!.localParticipant!.isScreenShareEnabled == true;
        }
      
      debugPrint('Room setup complete. Local participant: ${_room!.localParticipant?.identity}');
      debugPrint('Audio enabled: $_isAudioEnabled, Video enabled: $_isVideoEnabled, Screen sharing: $_isScreenSharing');
    }
  }

  void _onRoomUpdate() {
    if (mounted) {
      setState(() {
        _updateParticipants();
      });
    }
  }

  void _updateParticipants() {
    if (_room != null) {
      _participants = [];
      if (_room!.localParticipant != null) {
        _participants.add(_room!.localParticipant!);
      }
      // For now, just show local participant
      // Remote participants will be added when the API is properly implemented
    }
  }

  @override
  void dispose() {
    _room?.removeListener(_onRoomUpdate);
    _recordingSubscription?.cancel();
    RecordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildVideoArea(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _leaveRoom(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomModel?.name ?? 'Room',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_participants.length} participant${_participants.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: _showParticipantsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _showInviteDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_participants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.screen_share,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Share the room code with friends to start',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 16 / 9,
      ),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        return _ParticipantVideoTile(
          participant: participant,
          room: _room,
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
            onPressed: _toggleAudio,
            isActive: _isAudioEnabled,
          ),
          _ControlButton(
            icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            onPressed: _toggleVideo,
            isActive: _isVideoEnabled,
          ),
          _ControlButton(
            icon: _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            onPressed: _toggleScreenShare,
            isActive: _isScreenSharing,
            isPrimary: true,
          ),
          _ControlButton(
            icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
            onPressed: _toggleRecording,
            isActive: _isRecording,
            isDanger: _isRecording,
          ),
          _ControlButton(
            icon: Icons.call_end,
            onPressed: _leaveRoom,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  void _toggleAudio() async {
    if (_room?.localParticipant != null) {
      try {
        final isEnabled = (_room!.localParticipant!.isMicrophoneEnabled ?? false) == true;
        await _room!.localParticipant!.setMicrophoneEnabled(!isEnabled);
        setState(() => _isAudioEnabled = !isEnabled);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnabled ? 'Microphone disabled' : 'Microphone enabled'),
              backgroundColor: isEnabled ? Colors.orange : Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Audio toggle error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to toggle audio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleVideo() async {
    if (_room?.localParticipant != null) {
      try {
        final isEnabled = (_room!.localParticipant!.isCameraEnabled ?? false) == true;
        await _room!.localParticipant!.setCameraEnabled(!isEnabled);
        setState(() => _isVideoEnabled = !isEnabled);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnabled ? 'Camera disabled' : 'Camera enabled'),
              backgroundColor: isEnabled ? Colors.orange : Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Video toggle error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to toggle video: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleScreenShare() async {
    if (_room?.localParticipant != null) {
              final isEnabled = _room!.localParticipant!.isScreenShareEnabled == true;
      
      if (isEnabled) {
        // Stop screen sharing
        try {
                  debugPrint('Stopping screen share...');
        await ScreenShareService.stopScreenShare(null);
        setState(() => _isScreenSharing = false);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Screen sharing stopped'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          debugPrint('Error stopping screen share: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to stop screen sharing: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Start screen sharing with selection dialog
        _showScreenSelectionDialog();
      }
    }
  }

  void _showScreenSelectionDialog() async {
    // Load current quality settings
    final settings = await SettingsService.getInstance();
    final currentQuality = await settings.getSelectedQuality();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => ScreenSelectionDialog(
          currentQuality: currentQuality,
          onScreenSelected: (stream, quality) async {
            try {
              debugPrint('Starting screen share with quality: ${quality.name}');
              
              // Start screen sharing using mobile service
              final stream = await ScreenShareService.startScreenShare(
                quality: quality,
                includeAudio: true,
              );
              
              if (stream != null) {
                setState(() => _isScreenSharing = true);
              } else {
                throw Exception('Failed to start screen sharing');
              }
              
              // Save quality settings
              await settings.setSelectedQuality(quality);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Screen sharing started with ${quality.name} quality!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error starting screen share: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to start screen sharing: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await RecordingService.stopRecording();
    } else {
      // Start recording - we need a media stream
      if (_room?.localParticipant != null) {
        try {
          // For now, we'll show a dialog to select what to record
          _showRecordingOptionsDialog();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start recording: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active stream to record'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  void _showRecordingOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Recording'),
        content: const Text('What would you like to record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startScreenRecording();
            },
            child: const Text('Screen + Audio'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startCameraRecording();
            },
            child: const Text('Camera + Audio'),
          ),
        ],
      ),
    );
  }

  Future<void> _startScreenRecording() async {
    try {
      // Get screen share stream
      final stream = await ScreenShareService.startScreenShare(
        quality: _selectedQuality ?? QualitySettings.defaultQuality,
        includeAudio: true,
      );

      if (stream != null) {
        final success = await RecordingService.startRecording(
          mediaStream: stream,
          quality: _selectedQuality ?? QualitySettings.defaultQuality,
          roomName: _roomCode,
        );

        if (!success) {
          throw Exception('Failed to start recording');
        }
      } else {
        throw Exception('No screen share stream available');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start screen recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startCameraRecording() async {
    try {
      final success = await RecordingService.startRecording(
        mediaStream: null, // Not needed for mobile
        quality: _selectedQuality ?? QualitySettings.defaultQuality,
        roomName: _roomCode,
      );

      if (!success) {
        throw Exception('Failed to start recording');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start camera recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _leaveRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room'),
        content: const Text('Are you sure you want to leave the room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participants'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _participants.length,
            itemBuilder: (context, index) {
              final participant = _participants[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(participant.identity[0].toUpperCase()),
                ),
                title: Text(participant.identity),
                subtitle: Text(participant == _room?.localParticipant ? 'You' : 'Participant'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (participant.isMicrophoneEnabled == true)
                      const Icon(Icons.mic, size: 16, color: Colors.green)
                    else
                      const Icon(Icons.mic_off, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    if (participant.isCameraEnabled == true)
                      const Icon(Icons.videocam, size: 16, color: Colors.green)
                    else
                      const Icon(Icons.videocam_off, size: 16, color: Colors.red),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Invite Friends'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your friends:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _roomCode,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _roomCode));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied to clipboard')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or share this link:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'synqcast://join/$_roomCode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: 'synqcast://join/$_roomCode'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied to clipboard')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ParticipantVideoTile extends StatelessWidget {
  final Participant participant;
  final Room? room;

  const _ParticipantVideoTile({
    required this.participant,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Video rendering
          _buildVideoRenderer(),
          
          // Participant info overlay
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                participant.identity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          
          // Local participant indicator
          if (participant == room?.localParticipant)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          
          // Audio/Video status indicators
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                                 if ((participant.isMicrophoneEnabled ?? false) == false)
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: const BoxDecoration(
                       color: Colors.red,
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(
                       Icons.mic_off,
                       size: 12,
                       color: Colors.white,
                     ),
                   ),
                 const SizedBox(width: 4),
                 if ((participant.isCameraEnabled ?? false) == false)
                   Container(
                     padding: const EdgeInsets.all(4),
                     decoration: const BoxDecoration(
                       color: Colors.red,
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(
                       Icons.videocam_off,
                       size: 12,
                       color: Colors.white,
                     ),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoRenderer() {
    // Get video tracks from participant
    VideoTrack? videoTrack;
    
    // Check for screen share first, then camera
    if (participant.isScreenShareEnabled == true) {
      // Look for screen share video track
      for (final publication in participant.videoTrackPublications) {
        if (publication.track?.source == TrackSource.screenShareVideo) {
          videoTrack = publication.track as VideoTrack?;
          break;
        }
      }
    } else {
      // Look for camera video track
      for (final publication in participant.videoTrackPublications) {
        if (publication.track?.source == TrackSource.camera) {
          videoTrack = publication.track as VideoTrack?;
          break;
        }
      }
    }

    if (videoTrack != null) {
      // Show actual video using LiveKit's VideoRenderer
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  participant.isScreenShareEnabled == true 
                      ? Icons.screen_share 
                      : Icons.videocam,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  participant.isScreenShareEnabled == true 
                      ? 'Screen Sharing Active' 
                      : 'Camera Active',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '1280x720',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Show participant info with status
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: participant.isScreenShareEnabled == true 
                    ? Colors.orange 
                    : participant.isCameraEnabled == true 
                        ? Colors.green 
                        : Colors.grey[600],
                child: Icon(
                  participant.isScreenShareEnabled == true 
                      ? Icons.screen_share 
                      : participant.isCameraEnabled == true 
                          ? Icons.videocam 
                          : Icons.videocam_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                participant.identity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: participant.isScreenShareEnabled == true 
                      ? Colors.orange.withValues(alpha: 0.2)
                      : participant.isCameraEnabled == true 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  participant.isScreenShareEnabled == true ? 'Screen Sharing' : 
                  participant.isCameraEnabled == true ? 'Camera Active' : 'Camera Off',
                  style: TextStyle(
                    color: participant.isScreenShareEnabled == true 
                        ? Colors.orange 
                        : participant.isCameraEnabled == true 
                            ? Colors.green 
                            : Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isPrimary;
  final bool isDanger;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    if (isDanger) {
      backgroundColor = Colors.red;
      iconColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = isActive ? Colors.orange : Colors.blue;
      iconColor = Colors.white;
    } else {
      backgroundColor = isActive ? Colors.white : Colors.grey[600]!;
      iconColor = isActive ? Colors.black : Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: iconColor,
        iconSize: 24,
      ),
    );
  }
}
