#!/bin/bash

echo "🚀 Setting up SynqCast LiveKit Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

echo "📦 Installing token server dependencies..."
cd token_server
npm install
cd ..

echo "🐳 Starting LiveKit server with Docker..."
docker-compose up -d

echo "⏳ Waiting for LiveKit server to start..."
sleep 5

echo "🔑 Starting token server..."
cd token_server
npm start &
TOKEN_SERVER_PID=$!
cd ..

echo "⏳ Waiting for token server to start..."
sleep 3

echo "✅ Setup complete!"
echo ""
echo "🌐 LiveKit server: ws://localhost:7880"
echo "🔑 Token server: http://localhost:3000"
echo ""
echo "📱 You can now run your Flutter app:"
echo "   flutter run"
echo ""
echo "🛑 To stop the servers:"
echo "   docker-compose down"
echo "   kill $TOKEN_SERVER_PID"
echo ""
echo "🔍 To check if servers are running:"
echo "   curl http://localhost:3000/health"
echo "   docker-compose ps"
