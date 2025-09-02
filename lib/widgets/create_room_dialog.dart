import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../models/room.dart';

class CreateRoomDialog extends StatefulWidget {
  final RoomService roomService;

  const CreateRoomDialog({super.key, required this.roomService});

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _participantNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _participantNameController.text = 'User'; // Default name
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _participantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Text('Create New Room'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name',
                prefixIcon: Icon(Icons.meeting_room),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a room name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _participantNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating ? null : _createRoom,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Generate a secure room code
      final roomCode = _generateRoomCode();
      
      // Create the room
      final room = await widget.roomService.createRoom(
        _roomNameController.text.trim(),
        _participantNameController.text.trim(),
        roomCode: roomCode,
      );

      // Create room model for history
      final roomModel = RoomModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _roomNameController.text.trim(),
        hostName: _participantNameController.text.trim(),
        createdAt: DateTime.now(),
        participants: [
          ParticipantModel(
            id: '1',
            name: _participantNameController.text.trim(),
            isHost: true,
            joinedAt: DateTime.now(),
          ),
        ],
        inviteCode: roomCode,
      );

      if (mounted) {
        Navigator.of(context).pop();
        // Navigate to room screen with room model
        Navigator.pushNamed(context, '/room', arguments: roomModel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
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
}

class JoinRoomDialog extends StatefulWidget {
  final RoomService roomService;

  const JoinRoomDialog({super.key, required this.roomService});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  final _participantNameController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _participantNameController.text = 'User'; // Default name
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    _participantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: const Text('Join Room'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _roomCodeController,
              decoration: InputDecoration(
                labelText: 'Room Code',
                hintText: 'Enter room code',
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a room code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _participantNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isJoining ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isJoining ? null : _joinRoom,
          child: _isJoining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    try {
      final room = await widget.roomService.joinRoom(
        _roomCodeController.text.trim(),
        _participantNameController.text.trim(),
      );

      // Create room model for history
      final roomModel = RoomModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Room ${_roomCodeController.text.trim()}',
        hostName: 'Unknown',
        createdAt: DateTime.now(),
        participants: [
          ParticipantModel(
            id: '1',
            name: _participantNameController.text.trim(),
            isHost: false,
            joinedAt: DateTime.now(),
          ),
        ],
        inviteCode: _roomCodeController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        // Navigate to room screen with room model
        Navigator.pushNamed(context, '/room', arguments: roomModel);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }
}
