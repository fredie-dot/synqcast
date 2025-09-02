# LiveKit Setup Guide for SynqCast

This guide will help you set up LiveKit for your SynqCast app, enabling real-time screen sharing and communication.

## 🚀 Quick Start (Recommended)

### Option 1: Automated Setup
```bash
# Make the setup script executable and run it
chmod +x setup_livekit.sh
./setup_livekit.sh
```

### Option 2: Manual Setup
Follow the steps below to set up LiveKit manually.

## 📋 Prerequisites

- **Docker** (for running LiveKit server)
- **Node.js** (for token server)
- **Flutter** (already installed)

## 🔧 Step-by-Step Setup

### 1. Start LiveKit Server

```bash
# Start LiveKit server with Docker
docker-compose up -d

# Check if it's running
docker-compose ps
```

### 2. Install Token Server Dependencies

```bash
cd token_server
npm install
cd ..
```

### 3. Start Token Server

```bash
cd token_server
npm start
```

The token server will run on `http://localhost:3000`

### 4. Test the Setup

```bash
# Test token server
curl http://localhost:3000/health

# Test token generation
curl -X POST http://localhost:3000/token \
  -H "Content-Type: application/json" \
  -d '{"roomName":"test","participantName":"user"}'
```

### 5. Run Your Flutter App

```bash
flutter pub get
flutter run
```

## 🌐 Configuration

### Development vs Production

The app is configured for development by default. To switch to production:

1. **Update `config/livekit_config.dart`:**
   ```dart
   static const bool isProduction = true;
   ```

2. **Replace URLs with your LiveKit Cloud credentials:**
   ```dart
   static const String prodServerUrl = 'wss://your-project.livekit.cloud';
   static const String prodTokenServerUrl = 'https://your-backend.com';
   ```

### LiveKit Cloud Setup (Production)

1. **Sign up at [LiveKit Cloud](https://cloud.livekit.io)**
2. **Create a new project**
3. **Get your API keys from the dashboard**
4. **Update the configuration:**

   ```dart
   // In config/livekit_config.dart
   static const String apiKey = 'your-api-key';
   static const String apiSecret = 'your-api-secret';
   static const String prodServerUrl = 'wss://your-project.livekit.cloud';
   ```

## 🔍 Troubleshooting

### Common Issues

1. **Docker not running:**
   ```bash
   sudo systemctl start docker
   ```

2. **Port already in use:**
   ```bash
   # Check what's using the port
   lsof -i :7880
   lsof -i :3000
   
   # Kill the process or change ports in docker-compose.yml
   ```

3. **Token server not responding:**
   ```bash
   # Check if Node.js is installed
   node --version
   
   # Reinstall dependencies
   cd token_server
   rm -rf node_modules package-lock.json
   npm install
   ```

4. **Flutter app can't connect:**
   - Check if LiveKit server is running: `docker-compose ps`
   - Check if token server is running: `curl http://localhost:3000/health`
   - Verify URLs in `config/livekit_config.dart`

### Logs and Debugging

```bash
# LiveKit server logs
docker-compose logs livekit

# Token server logs (if running in terminal)
# Check the terminal where you ran `npm start`

# Flutter app logs
flutter logs
```

## 🛑 Stopping the Servers

```bash
# Stop LiveKit server
docker-compose down

# Stop token server (if running in background)
pkill -f "node server.js"
```

## 📱 Testing the App

1. **Create a room** using the floating action button
2. **Join the room** from another device or browser
3. **Test screen sharing** and audio features
4. **Check participant management**

## 🔐 Security Notes

- **Development keys** are for testing only
- **Production keys** should be kept secure
- **Token server** should be deployed securely in production
- **HTTPS** is required for production

## 📚 Additional Resources

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit Cloud](https://cloud.livekit.io)
- [Flutter LiveKit Client](https://pub.dev/packages/livekit_client)

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all services are running
3. Check the logs for error messages
4. Ensure your network allows WebSocket connections
