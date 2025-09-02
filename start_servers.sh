#!/bin/bash

echo "🚀 Starting SynqCast Servers..."
echo "================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Start LiveKit server
echo "1. Starting LiveKit server..."
if curl -s http://localhost:7880 > /dev/null 2>&1; then
    echo "   ✅ LiveKit server is already running"
else
    echo "   🚀 Starting LiveKit server..."
    docker run --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp livekit/livekit-server --dev > /dev/null 2>&1 &
    LIVEKIT_PID=$!
    echo "   ✅ LiveKit server started (PID: $LIVEKIT_PID)"
    
    # Wait for LiveKit to start
    echo "   ⏳ Waiting for LiveKit server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:7880 > /dev/null 2>&1; then
            echo "   ✅ LiveKit server is ready!"
            break
        fi
        sleep 1
    done
fi

# Start Token server
echo "2. Starting Token server..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "   ✅ Token server is already running"
else
    echo "   🚀 Starting Token server..."
    cd token_server
    npm start > /dev/null 2>&1 &
    TOKEN_PID=$!
    cd ..
    echo "   ✅ Token server started (PID: $TOKEN_PID)"
    
    # Wait for Token server to start
    echo "   ⏳ Waiting for Token server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo "   ✅ Token server is ready!"
            break
        fi
        sleep 1
    done
fi

# Test token generation
echo "3. Testing token generation..."
if curl -s -X POST http://localhost:3000/token \
  -H "Content-Type: application/json" \
  -d '{"roomName":"test","participantName":"test"}' | grep -q "token"; then
    echo "   ✅ Token generation working"
else
    echo "   ❌ Token generation failed"
fi

echo ""
echo "🎉 All servers are running!"
echo "================================"
echo "📡 LiveKit Server: http://localhost:7880"
echo "🔑 Token Server: http://localhost:3000"
echo ""
echo "🚀 You can now run: flutter run -d chrome --web-port=8080"
echo ""
echo "💡 To stop servers, press Ctrl+C or run: pkill -f 'livekit-server' && pkill -f 'node.*server.js'"
