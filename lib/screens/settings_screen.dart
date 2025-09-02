import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../config/quality_settings.dart';
import '../config/room_templates.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String)? onThemeChanged;
  
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  QualitySettings _selectedQuality = QualitySettings.defaultQuality;
  RoomTemplate _selectedTemplate = RoomTemplate.defaultTemplate;
  bool _autoRecord = false;
  bool _enableChat = true;
  bool _lowLatency = false;
  int _maxParticipants = 10;
  String _themeMode = 'system';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settingsService = await SettingsService.getInstance();
      
      // Load quality with fallback to default if not found
      try {
        _selectedQuality = await _settingsService.getSelectedQuality();
        // Verify the quality exists in current presets
        final qualityExists = QualitySettings.presets.any((q) => q.name == _selectedQuality.name);
        if (!qualityExists) {
          _selectedQuality = QualitySettings.defaultQuality;
          await _settingsService.setSelectedQuality(_selectedQuality);
        }
      } catch (e) {
        debugPrint('Error loading quality settings: $e');
        _selectedQuality = QualitySettings.defaultQuality;
        await _settingsService.setSelectedQuality(_selectedQuality);
      }
      
      // Load template with fallback to default if not found
      try {
        _selectedTemplate = await _settingsService.getSelectedTemplate();
        // Verify the template exists in current templates list
        final templateExists = RoomTemplate.templates.any((t) => t.id == _selectedTemplate.id);
        if (!templateExists) {
          _selectedTemplate = RoomTemplate.defaultTemplate;
          await _settingsService.setSelectedTemplate(_selectedTemplate.id);
        }
      } catch (e) {
        debugPrint('Error loading template settings: $e');
        _selectedTemplate = RoomTemplate.defaultTemplate;
        await _settingsService.setSelectedTemplate(_selectedTemplate.id);
      }
      
      // Load other settings with error handling
      try {
        _autoRecord = await _settingsService.getAutoRecord();
        _enableChat = await _settingsService.getEnableChat();
        _lowLatency = await _settingsService.getLowLatency();
        _maxParticipants = await _settingsService.getMaxParticipants();
        _themeMode = await _settingsService.getThemeMode();
      } catch (e) {
        debugPrint('Error loading other settings: $e');
        // Use default values
        _autoRecord = false;
        _enableChat = true;
        _lowLatency = false;
        _maxParticipants = 10;
        _themeMode = 'system';
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Critical error loading settings: $e');
      // Set all defaults and continue
      _selectedQuality = QualitySettings.defaultQuality;
      _selectedTemplate = RoomTemplate.defaultTemplate;
      _autoRecord = false;
      _enableChat = true;
      _lowLatency = false;
      _maxParticipants = 10;
      _themeMode = 'system';
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Refresh Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                try {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQualitySettings(),
                        const SizedBox(height: 24),
                        _buildRoomTemplates(),
                        const SizedBox(height: 24),
                        _buildRoomSettings(),
                        const SizedBox(height: 24),
                        _buildAppSettings(),
                        const SizedBox(height: 24),
                        _buildActions(),
                      ],
                    ),
                  );
                } catch (e) {
                  debugPrint('Error building settings screen: $e');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Settings Error',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('An error occurred while loading settings: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSettings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildQualitySettings() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.high_quality, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Quality Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: QualitySettings.presets.any((q) => q.name == _selectedQuality.name) 
                  ? _selectedQuality.name 
                  : QualitySettings.defaultQuality.name,
              decoration: InputDecoration(
                labelText: 'Default Stream Quality',
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
              items: QualitySettings.presets.map((quality) {
                return DropdownMenuItem(
                  value: quality.name,
                  child: Text(
                    '${quality.name} (${quality.width}x${quality.height} @ ${quality.frameRate}fps)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  final quality = QualitySettings.presets.firstWhere(
                    (q) => q.name == value,
                    orElse: () => QualitySettings.defaultQuality,
                  );
                  setState(() => _selectedQuality = quality);
                  await _settingsService.setSelectedQuality(quality);
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Quality: ${_selectedQuality.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Resolution: ${_selectedQuality.width}x${_selectedQuality.height}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Frame Rate: ${_selectedQuality.frameRate} FPS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Bitrate: ${_selectedQuality.bitrate} kbps',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Description: ${_selectedQuality.description}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTemplates() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                const Text(
                  'Room Templates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: RoomTemplate.templates.any((t) => t.id == _selectedTemplate.id) 
                  ? _selectedTemplate.id 
                  : RoomTemplate.defaultTemplate.id,
              decoration: InputDecoration(
                labelText: 'Default Room Template',
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
              items: RoomTemplate.templates.map((template) {
                return DropdownMenuItem(
                  value: template.id,
                  child: Text(
                    '${template.icon} ${template.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  final template = RoomTemplate.templates.firstWhere(
                    (t) => t.id == value,
                    orElse: () => RoomTemplate.defaultTemplate,
                  );
                  setState(() => _selectedTemplate = template);
                  await _settingsService.setSelectedTemplate(template.id);
                }
              },
            ),
            const SizedBox(height: 12),
            if (_selectedTemplate.features.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_selectedTemplate.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            feature,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSettings() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.meeting_room, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                const Text(
                  'Room Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Record'),
              subtitle: const Text('Automatically start recording when room is created'),
              value: _autoRecord,
              onChanged: (value) async {
                setState(() => _autoRecord = value);
                await _settingsService.setAutoRecord(value);
              },
            ),
            SwitchListTile(
              title: const Text('Enable Chat'),
              subtitle: const Text('Allow participants to send messages'),
              value: _enableChat,
              onChanged: (value) async {
                setState(() => _enableChat = value);
                await _settingsService.setEnableChat(value);
              },
            ),
            SwitchListTile(
              title: const Text('Low Latency Mode'),
              subtitle: const Text('Optimize for gaming and real-time applications'),
              value: _lowLatency,
              onChanged: (value) async {
                setState(() => _lowLatency = value);
                await _settingsService.setLowLatency(value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _maxParticipants,
              decoration: InputDecoration(
                labelText: 'Maximum Participants',
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
              items: [5, 10, 15, 20, 25, 30].map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count participants'),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _maxParticipants = value);
                  await _settingsService.setMaxParticipants(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'App Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _themeMode,
              decoration: InputDecoration(
                labelText: 'Theme Mode',
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
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System Default')),
                DropdownMenuItem(value: 'light', child: Text('Light Theme')),
                DropdownMenuItem(value: 'dark', child: Text('Dark Theme')),
              ],
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _themeMode = value);
                  await _settingsService.setThemeMode(value);
                  widget.onThemeChanged?.call(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetSettings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset to Defaults'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportSettings,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _settingsService.resetSettings();
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }

  Future<void> _exportSettings() async {
    try {
      final settings = await _settingsService.getAllSettings();
      // In a real app, you would export this to a file
              debugPrint('Settings to export: $settings');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings exported (check console)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export settings: $e')),
        );
      }
    }
  }
}
