#!/bin/bash

echo "🚀 Preparing SynqCast Token Server for Glitch Deployment"
echo "========================================================"

# Check if we're in the right directory
if [ ! -f "token_server/server.js" ]; then
    echo "❌ Error: Please run this script from the SynqCast project root"
    exit 1
fi

echo "✅ Token server files found"
echo ""

echo "📋 Files ready for Glitch deployment:"
echo "   - token_server/server.js"
echo "   - token_server/package.json"
echo "   - token_server/glitch.json"
echo "   - token_server/GLITCH_README.md"
echo ""

echo "🌐 Deploy to Glitch:"
echo "1. Go to https://glitch.com"
echo "2. Click 'New Project' → 'Import from GitHub'"
echo "3. Or manually create a new project and copy these files"
echo ""

echo "📝 Manual Setup Steps:"
echo "1. Create new Glitch project"
echo "2. Copy server.js content to main.js (or rename server.js to main.js)"
echo "3. Copy package.json content"
echo "4. Copy glitch.json content"
echo "5. Add .env file with:"
echo "   LIVEKIT_API_KEY=devkey"
echo "   LIVEKIT_API_SECRET=secret"
echo ""

echo "🔗 After deployment, update your Flutter app config:"
echo "   - Change isProduction to true"
echo "   - Update prodTokenServerUrl to your Glitch URL"
echo ""

echo "📱 Test the deployment:"
echo "   - Visit your-project.glitch.me/health"
echo "   - Should return: {\"status\":\"ok\"}"
echo ""

echo "🎯 Goal: Your app will work independently from your computer!"
echo "========================================================"
