import 'package:flutter/material.dart';
import '../config/quality_settings.dart';
import '../services/screen_share_service.dart';

class ScreenSelectionDialog extends StatefulWidget {
  final Function(MediaStream stream, QualitySettings quality) onScreenSelected;
  final QualitySettings currentQuality;

  const ScreenSelectionDialog({
    super.key,
    required this.onScreenSelected,
    required this.currentQuality,
  });

  @override
  State<ScreenSelectionDialog> createState() => _ScreenSelectionDialogState();
}

class _ScreenSelectionDialogState extends State<ScreenSelectionDialog> {
  QualitySettings _selectedQuality = QualitySettings.defaultQuality;
  bool _includeAudio = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.currentQuality;
  }

  Future<void> _startScreenShare() async {
    setState(() => _isLoading = true);

    try {
      // Check if screen sharing is supported
      final isSupported = await ScreenShareService.isSupported();
      if (!isSupported) {
        throw Exception('Screen sharing is not supported in this browser');
      }

      // Start screen sharing with quality settings
      final stream = await ScreenShareService.startScreenShare(
        quality: _selectedQuality,
        includeAudio: _includeAudio,
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        // Pass the stream and quality settings to the callback
        widget.onScreenSelected(
          MediaStream(stream: stream),
          _selectedQuality,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start screen sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.screen_share, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Share Screen'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quality Selection
            const Text(
              'Quality Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedQuality.name,
              decoration: InputDecoration(
                labelText: 'Stream Quality',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(quality.name),
                      Text(
                        quality.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
            const SizedBox(height: 16),

            // Quality Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quality Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Resolution: ${_selectedQuality.width}x${_selectedQuality.height}'),
                  Text('Frame Rate: ${_selectedQuality.frameRate} FPS'),
                  Text('Bitrate: ${_selectedQuality.bitrate} kbps'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audio Option
            CheckboxListTile(
              title: const Text('Include System Audio'),
              subtitle: const Text('Share audio from your computer'),
              value: _includeAudio,
              onChanged: (value) {
                setState(() => _includeAudio = value ?? true);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to share:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Click "Start Sharing"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '• Choose what to share (screen, window, or tab)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '• Grant permission when prompted',
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
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startScreenShare,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Start Sharing'),
        ),
      ],
    );
  }
}

// MediaStream wrapper for browser MediaStream
class MediaStream {
  final dynamic stream;
  
  MediaStream({this.stream});
}
