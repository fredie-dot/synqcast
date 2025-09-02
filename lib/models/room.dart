class RoomModel {
  final String id;
  final String name;
  final String hostName;
  final DateTime createdAt;
  final List<ParticipantModel> participants;
  final bool isActive;
  final String? inviteCode;

  RoomModel({
    required this.id,
    required this.name,
    required this.hostName,
    required this.createdAt,
    this.participants = const [],
    this.isActive = true,
    this.inviteCode,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hostName: json['hostName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      inviteCode: json['inviteCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostName': hostName,
      'createdAt': createdAt.toIso8601String(),
      'participants': participants.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'inviteCode': inviteCode,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel.fromJson(map);
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? hostName,
    DateTime? createdAt,
    List<ParticipantModel>? participants,
    bool? isActive,
    String? inviteCode,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      hostName: hostName ?? this.hostName,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      isActive: isActive ?? this.isActive,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

class ParticipantModel {
  final String id;
  final String name;
  final bool isHost;
  final bool isScreenSharing;
  final bool isAudioEnabled;
  final DateTime joinedAt;

  ParticipantModel({
    required this.id,
    required this.name,
    this.isHost = false,
    this.isScreenSharing = false,
    this.isAudioEnabled = true,
    required this.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isScreenSharing: json['isScreenSharing'] as bool? ?? false,
      isAudioEnabled: json['isAudioEnabled'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'isScreenSharing': isScreenSharing,
      'isAudioEnabled': isAudioEnabled,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  ParticipantModel copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isScreenSharing,
    bool? isAudioEnabled,
    DateTime? joinedAt,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
