#!/bin/bash

echo "🧪 Testing SynqCast App Improvements"
echo "====================================="

# Check if servers are running
echo "1. Checking servers..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "   ✅ Token server is running"
else
    echo "   ❌ Token server is not running"
    echo "   Starting token server..."
    cd token_server && npm start &
    sleep 3
fi

if curl -s http://localhost:7880 > /dev/null 2>&1; then
    echo "   ✅ LiveKit server is running"
else
    echo "   ❌ LiveKit server is not running"
    echo "   Starting LiveKit server..."
    docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp livekit/livekit-server --dev &
    sleep 5
fi

# Test token generation
echo "2. Testing token generation..."
TOKEN_RESPONSE=$(curl -s -X POST http://localhost:3000/token \
  -H "Content-Type: application/json" \
  -d '{"roomName":"test","participantName":"test"}')

if echo "$TOKEN_RESPONSE" | grep -q "token"; then
    echo "   ✅ Token generation working"
else
    echo "   ❌ Token generation failed"
    echo "   Response: $TOKEN_RESPONSE"
fi

# Check app icons
echo "3. Checking app icons..."
if [ -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
    echo "   ✅ Custom app icons exist"
else
    echo "   ❌ Custom app icons missing"
fi

# Check permission service
echo "4. Checking permission service..."
if [ -f "lib/services/permission_service.dart" ]; then
    echo "   ✅ Permission service exists"
else
    echo "   ❌ Permission service missing"
fi

# Check splash screen
echo "5. Checking splash screen..."
if [ -f "lib/screens/splash_screen.dart" ]; then
    echo "   ✅ Splash screen exists"
else
    echo "   ❌ Splash screen missing"
fi

# Check main.dart integration
echo "6. Checking main.dart integration..."
if grep -q "SplashScreen" lib/main.dart; then
    echo "   ✅ Splash screen integrated in main.dart"
else
    echo "   ❌ Splash screen not integrated in main.dart"
fi

echo ""
echo "🎯 Summary:"
echo "   - Storage permissions: Fixed for mobile"
echo "   - Splash screen: Added with animations"
echo "   - App title: Professional design (no gradients)"
echo "   - Custom app icon: Created with 'SC' design"
echo "   - Token server: Should be working"
echo "   - LiveKit server: Should be working"
echo ""
echo "🚀 To test the app:"
echo "   1. Run: flutter run -d chrome --web-port=8080"
echo "   2. Or connect Android device and run: flutter run"
echo "   3. You should see the splash screen first"
echo "   4. Then permissions will be requested"
echo "   5. Finally the main app will load"
echo ""
echo "📱 For mobile testing:"
echo "   - Connect your Android device via USB"
echo "   - Enable USB debugging"
echo "   - Run: flutter run"
echo "   - The app will request storage permissions on startup"
