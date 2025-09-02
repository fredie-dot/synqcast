import 'quality_settings.dart';

class RoomTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final QualitySettings quality;
  final Map<String, dynamic> settings;
  final List<String> features;

  const RoomTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.quality,
    required this.settings,
    required this.features,
  });

  static const List<RoomTemplate> templates = [
    RoomTemplate(
      id: 'gaming',
      name: 'Gaming Stream',
      description: 'High FPS, low latency for gaming',
      icon: '🎮',
      quality: QualitySettings(
        name: 'Ultra',
        width: 1920,
        height: 1080,
        frameRate: 60,
        bitrate: 4000,
        description: 'Optimized for gaming',
      ),
      settings: {
        'maxParticipants': 10,
        'enableRecording': true,
        'enableChat': true,
        'autoRecord': false,
        'lowLatency': true,
      },
      features: [
        'High FPS (60fps)',
        'Low Latency Mode',
        'Gaming Optimized',
        'Screen Recording',
      ],
    ),
    RoomTemplate(
      id: 'business',
      name: 'Business Presentation',
      description: 'High quality for professional presentations',
      icon: '💼',
      quality: QualitySettings(
        name: 'High',
        width: 1920,
        height: 1080,
        frameRate: 30,
        bitrate: 3000,
        description: 'Professional quality',
      ),
      settings: {
        'maxParticipants': 20,
        'enableRecording': true,
        'enableChat': false,
        'autoRecord': true,
        'lowLatency': false,
      },
      features: [
        'High Quality (1080p)',
        'Auto Recording',
        'Professional Settings',
        'Large Audience Support',
      ],
    ),
    RoomTemplate(
      id: 'education',
      name: 'Educational Session',
      description: 'Balanced quality for teaching and learning',
      icon: '📚',
      quality: QualitySettings(
        name: 'Standard',
        width: 1280,
        height: 720,
        frameRate: 30,
        bitrate: 1500,
        description: 'Educational quality',
      ),
      settings: {
        'maxParticipants': 15,
        'enableRecording': true,
        'enableChat': true,
        'autoRecord': false,
        'lowLatency': false,
      },
      features: [
        'Balanced Quality',
        'Interactive Chat',
        'Recording Support',
        'Student-Friendly',
      ],
    ),
    RoomTemplate(
      id: 'social',
      name: 'Social Hangout',
      description: 'Casual streaming for friends and family',
      icon: '👥',
      quality: QualitySettings(
        name: 'Standard',
        width: 1280,
        height: 720,
        frameRate: 30,
        bitrate: 1500,
        description: 'Social quality',
      ),
      settings: {
        'maxParticipants': 8,
        'enableRecording': false,
        'enableChat': true,
        'autoRecord': false,
        'lowLatency': false,
      },
      features: [
        'Casual Quality',
        'Group Chat',
        'Easy Setup',
        'Friend-Friendly',
      ],
    ),
    RoomTemplate(
      id: 'custom',
      name: 'Custom Room',
      description: 'Create your own settings',
      icon: '⚙️',
      quality: QualitySettings.defaultQuality,
      settings: {
        'maxParticipants': 10,
        'enableRecording': false,
        'enableChat': true,
        'autoRecord': false,
        'lowLatency': false,
      },
      features: [
        'Customizable Settings',
        'Flexible Options',
        'Personalized Experience',
      ],
    ),
  ];

  static const RoomTemplate defaultTemplate = RoomTemplate(
    id: 'custom',
    name: 'Custom Room',
    description: 'Create your own settings',
    icon: '⚙️',
    quality: QualitySettings.defaultQuality,
    settings: {
      'maxParticipants': 10,
      'enableRecording': false,
      'enableChat': true,
      'autoRecord': false,
      'lowLatency': false,
    },
    features: [
      'Customizable Settings',
      'Flexible Options',
      'Personalized Experience',
    ],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'quality': quality.toMap(),
      'settings': settings,
      'features': features,
    };
  }

  factory RoomTemplate.fromMap(Map<String, dynamic> map) {
    return RoomTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      quality: QualitySettings.fromMap(map['quality'] ?? {}),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      features: List<String>.from(map['features'] ?? []),
    );
  }
}
