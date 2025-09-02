import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../services/settings_service.dart';
import '../config/room_templates.dart';
import '../config/quality_settings.dart';
import '../models/room.dart';

class EnhancedCreateRoomDialog extends StatefulWidget {
  final RoomService roomService;

  const EnhancedCreateRoomDialog({
    super.key,
    required this.roomService,
  });

  @override
  State<EnhancedCreateRoomDialog> createState() => _EnhancedCreateRoomDialogState();
}

class _EnhancedCreateRoomDialogState extends State<EnhancedCreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _participantNameController = TextEditingController();
  
  RoomTemplate _selectedTemplate = RoomTemplate.defaultTemplate;
  QualitySettings _selectedQuality = QualitySettings.defaultQuality;
  bool _isCreating = false;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _participantNameController.text = 'User';
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final settings = await SettingsService.getInstance();
    _selectedTemplate = await settings.getSelectedTemplate();
    _selectedQuality = await settings.getSelectedQuality();
    setState(() {});
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
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Create New Room'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Template Selection
                const Text(
                  'Room Template',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: RoomTemplate.templates.length + 1, // +1 for custom
                    itemBuilder: (context, index) {
                      final template = index == RoomTemplate.templates.length
                          ? RoomTemplate.defaultTemplate
                          : RoomTemplate.templates[index];
                      
                      final isSelected = template.id == _selectedTemplate.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTemplate = template;
                            _selectedQuality = template.quality;
                          });
                        },
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.grey[50],
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(template.icon, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      template.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.blue[700] : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Template Features
                if (_selectedTemplate.features.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Features:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...(_selectedTemplate.features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green[600], size: 16),
                              const SizedBox(width: 8),
                              Text(feature, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Basic Information
                const Text(
                  'Room Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
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
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person),
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
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Advanced Settings Toggle
                InkWell(
                  onTap: () {
                    setState(() => _showAdvancedSettings = !_showAdvancedSettings);
                  },
                  child: Row(
                    children: [
                      Icon(
                        _showAdvancedSettings ? Icons.expand_less : Icons.expand_more,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Advanced Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Advanced Settings
                if (_showAdvancedSettings) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quality Settings
                        const Text(
                          'Quality Settings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedQuality.name,
                          decoration: const InputDecoration(
                            labelText: 'Stream Quality',
                            border: OutlineInputBorder(),
                          ),
                          items: QualitySettings.presets.map((quality) {
                            return DropdownMenuItem(
                              value: quality.name,
                              child: Text(quality.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final quality = QualitySettings.presets.firstWhere(
                                (q) => q.name == value,
                                orElse: () => QualitySettings.defaultQuality,
                              );
                              setState(() => _selectedQuality = quality);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Resolution: ${_selectedQuality.width}x${_selectedQuality.height} • '
                          'FPS: ${_selectedQuality.frameRate} • '
                          'Bitrate: ${_selectedQuality.bitrate} kbps',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
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
              : const Text('Create Room'),
        ),
      ],
    );
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Save settings
      final settings = await SettingsService.getInstance();
      await settings.setSelectedTemplate(_selectedTemplate.id);
      await settings.setSelectedQuality(_selectedQuality);

      // Generate a secure room code
      final roomCode = _generateRoomCode();

      // Create room
      await widget.roomService.createRoom(
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
