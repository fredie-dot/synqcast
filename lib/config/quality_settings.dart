class QualitySettings {
  final String name;
  final int width;
  final int height;
  final int frameRate;
  final int bitrate;
  final String description;

  const QualitySettings({
    required this.name,
    required this.width,
    required this.height,
    required this.frameRate,
    required this.bitrate,
    required this.description,
  });

  static const List<QualitySettings> presets = [
    QualitySettings(
      name: 'Low',
      width: 640,
      height: 480,
      frameRate: 15,
      bitrate: 500,
      description: 'Good for slow connections',
    ),
    QualitySettings(
      name: 'Standard',
      width: 1280,
      height: 720,
      frameRate: 30,
      bitrate: 1500,
      description: 'Balanced quality and performance',
    ),
    QualitySettings(
      name: 'High',
      width: 1920,
      height: 1080,
      frameRate: 30,
      bitrate: 3000,
      description: 'High quality for fast connections',
    ),
    QualitySettings(
      name: 'Ultra',
      width: 2560,
      height: 1440,
      frameRate: 60,
      bitrate: 6000,
      description: 'Ultra HD for gaming and presentations',
    ),
  ];

  static const QualitySettings defaultQuality = QualitySettings(
    name: 'Standard',
    width: 1280,
    height: 720,
    frameRate: 30,
    bitrate: 1500,
    description: 'Balanced quality and performance',
  );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'width': width,
      'height': height,
      'frameRate': frameRate,
      'bitrate': bitrate,
      'description': description,
    };
  }

  factory QualitySettings.fromMap(Map<String, dynamic> map) {
    return QualitySettings(
      name: map['name'] ?? '',
      width: map['width'] ?? 1280,
      height: map['height'] ?? 720,
      frameRate: map['frameRate'] ?? 30,
      bitrate: map['bitrate'] ?? 1500,
      description: map['description'] ?? '',
    );
  }
}
