#!/bin/bash

echo "🌐 Starting SynqCast for Web Development..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start LiveKit server
echo "📡 Starting LiveKit server..."
docker-compose up -d

# Wait for LiveKit to be ready
echo "⏳ Waiting for LiveKit server to be ready..."
sleep 5

# Check if token server is running
if ! curl -s http://localhost:3000/health > /dev/null; then
    echo "🔑 Starting token server..."
    cd token_server
    npm start &
    cd ..
    sleep 3
else
    echo "✅ Token server is already running"
fi

# Test the setup
echo "🧪 Testing server setup..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Token server is ready"
else
    echo "❌ Token server failed to start"
    exit 1
fi

if curl -s http://localhost:7880 > /dev/null 2>&1; then
    echo "✅ LiveKit server is ready"
else
    echo "❌ LiveKit server failed to start"
    exit 1
fi

echo "🎉 All servers are running!"
echo "📱 You can now run: flutter run -d chrome --web-port=8080"
echo ""
echo "To stop servers:"
echo "  docker-compose down"
echo "  pkill -f 'node server.js'"
