class LiveKitConfig {
  // Development settings (localhost)
  static const String devServerUrl = 'ws://localhost:7880';
  static const String devTokenServerUrl = 'http://localhost:3000';
  
  // Production settings (replace with your LiveKit Cloud credentials)
  static const String prodServerUrl = 'wss://your-project.livekit.cloud';
  static const String prodTokenServerUrl = 'https://your-backend.com';
  
  // API Keys (replace with your actual keys)
  static const String apiKey = 'devkey';
  static const String apiSecret = 'secret';
  
  // Environment
  static const bool isProduction = false;
  
  // Get current server URL based on environment
  static String get serverUrl => isProduction ? prodServerUrl : devServerUrl;
  static String get tokenServerUrl => isProduction ? prodTokenServerUrl : devTokenServerUrl;
  
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
