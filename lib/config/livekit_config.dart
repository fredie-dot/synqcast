import 'package:flutter/foundation.dart';

class LiveKitConfig {
  // Your computer's IP address (update this to your actual IP)
  static const String computerIP = '192.168.1.55';
  
  // Development settings
  static const String devServerUrl = 'ws://192.168.1.55:7880';
  static const String devTokenServerUrl = 'http://192.168.1.55:3000';
  
  // Web development settings (localhost for web)
  static const String webServerUrl = 'ws://localhost:7880';
  static const String webTokenServerUrl = 'http://localhost:3000';
  
  // Production settings (cloud servers)
  static const String prodServerUrl = 'wss://your-project.livekit.cloud';
  static const String prodTokenServerUrl = 'https://synqcast-token-server.onrender.com';
  
  // API Keys (replace with your actual keys)
  static const String apiKey = 'devkey';
  static const String apiSecret = 'secret';
  
  // Environment - NOW USING CLOUD SERVER!
  static const bool isProduction = true;
  
  // Get current server URL based on environment and platform
  static String get serverUrl {
    if (isProduction) return prodServerUrl;
    if (kIsWeb) return webServerUrl;
    return devServerUrl;
  }
  
  static String get tokenServerUrl {
    if (isProduction) return prodTokenServerUrl;
    if (kIsWeb) return webTokenServerUrl;
    return devTokenServerUrl;
  }
  
  // Room settings
  static const int maxParticipants = 10;
  static const int roomTimeoutMinutes = 60;
  
  // Video settings
  static const int videoWidth = 1280;
  static const int videoHeight = 720;
  static const int videoFps = 30;
  static const int videoBitrate = 2000;
  
  // Audio settings
  static const int audioSampleRate = 48000;
  static const int audioChannels = 2;
  static const int audioBitrate = 128;
}
