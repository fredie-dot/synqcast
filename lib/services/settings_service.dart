import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/quality_settings.dart';
import '../config/room_templates.dart';

class SettingsService {
  static const String _qualityKey = 'selected_quality';
  static const String _templateKey = 'selected_template';
  static const String _autoRecordKey = 'auto_record';
  static const String _enableChatKey = 'enable_chat';
  static const String _lowLatencyKey = 'low_latency';
  static const String _maxParticipantsKey = 'max_participants';
  static const String _themeKey = 'theme_mode';
  static const String _favoriteRoomsKey = 'favorite_rooms';

  static SettingsService? _instance;
  static SharedPreferences? _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Quality Settings
  Future<QualitySettings> getSelectedQuality() async {
    final qualityName = _prefs?.getString(_qualityKey);
    if (qualityName != null) {
      try {
        final quality = QualitySettings.presets.firstWhere(
          (q) => q.name == qualityName,
          orElse: () => QualitySettings.defaultQuality,
        );
        return quality;
      } catch (e) {
        debugPrint('Error parsing quality settings: $e');
      }
    }
    return QualitySettings.defaultQuality;
  }

  Future<void> setSelectedQuality(QualitySettings quality) async {
    await _prefs?.setString(_qualityKey, quality.name);
  }

  // Room Template
  Future<RoomTemplate> getSelectedTemplate() async {
    final templateId = _prefs?.getString(_templateKey);
    if (templateId != null) {
      try {
        final template = RoomTemplate.templates.firstWhere(
          (t) => t.id == templateId,
          orElse: () => RoomTemplate.defaultTemplate,
        );
        return template;
      } catch (e) {
        debugPrint('Error parsing template settings: $e');
      }
    }
    return RoomTemplate.defaultTemplate;
  }

  Future<void> setSelectedTemplate(String templateId) async {
    await _prefs?.setString(_templateKey, templateId);
  }

  // Room Settings
  Future<bool> getAutoRecord() async {
    return _prefs?.getBool(_autoRecordKey) ?? false;
  }

  Future<void> setAutoRecord(bool value) async {
    await _prefs?.setBool(_autoRecordKey, value);
  }

  Future<bool> getEnableChat() async {
    return _prefs?.getBool(_enableChatKey) ?? true;
  }

  Future<void> setEnableChat(bool value) async {
    await _prefs?.setBool(_enableChatKey, value);
  }

  Future<bool> getLowLatency() async {
    return _prefs?.getBool(_lowLatencyKey) ?? false;
  }

  Future<void> setLowLatency(bool value) async {
    await _prefs?.setBool(_lowLatencyKey, value);
  }

  Future<int> getMaxParticipants() async {
    return _prefs?.getInt(_maxParticipantsKey) ?? 10;
  }

  Future<void> setMaxParticipants(int value) async {
    await _prefs?.setInt(_maxParticipantsKey, value);
  }

  // Theme Settings
  Future<String> getThemeMode() async {
    return _prefs?.getString(_themeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_themeKey, mode);
  }

  // Favorite Rooms
  Future<List<String>> getFavoriteRooms() async {
    return _prefs?.getStringList(_favoriteRoomsKey) ?? [];
  }

  Future<void> addFavoriteRoom(String roomId) async {
    final favorites = await getFavoriteRooms();
    if (!favorites.contains(roomId)) {
      favorites.add(roomId);
      await _prefs?.setStringList(_favoriteRoomsKey, favorites);
    }
  }

  Future<void> removeFavoriteRoom(String roomId) async {
    final favorites = await getFavoriteRooms();
    favorites.remove(roomId);
    await _prefs?.setStringList(_favoriteRoomsKey, favorites);
  }

  // Reset all settings
  Future<void> resetSettings() async {
    await _prefs?.clear();
  }

  // Get all settings as a map
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'quality': (await getSelectedQuality()).toMap(),
      'template': (await getSelectedTemplate()).id,
      'autoRecord': await getAutoRecord(),
      'enableChat': await getEnableChat(),
      'lowLatency': await getLowLatency(),
      'maxParticipants': await getMaxParticipants(),
      'themeMode': await getThemeMode(),
      'favoriteRooms': await getFavoriteRooms(),
    };
  }
}
