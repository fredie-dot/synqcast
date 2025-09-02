#!/bin/bash

echo "☁️ Deploying SynqCast to Cloud..."
echo "=================================="

echo "🚀 Option 1: Deploy to Vercel (Recommended - Free)"
echo "   - Go to https://vercel.com"
echo "   - Sign up with GitHub"
echo "   - Install Vercel CLI: npm i -g vercel"
echo "   - Run: cd token_server && vercel"
echo ""

echo "🚀 Option 2: Deploy to Railway (Free Tier)"
echo "   - Go to https://railway.app"
echo "   - Sign up with GitHub"
echo "   - Connect your repository"
echo "   - Deploy automatically"
echo ""

echo "🚀 Option 3: Deploy to Heroku (Free Tier)"
echo "   - Go to https://heroku.com"
echo "   - Sign up for free account"
echo "   - Install Heroku CLI"
echo "   - Run: cd token_server && heroku create && git push heroku main"
echo ""

echo "📋 After deploying, you'll get a URL like:"
echo "   https://your-app.vercel.app"
echo "   https://your-app.railway.app"
echo "   https://your-app.herokuapp.com"
echo ""

echo "🔧 Then update lib/config/livekit_config.dart with:"
echo "   - Your cloud token server URL"
echo "   - LiveKit Cloud credentials"
echo ""

echo "📱 Finally, build a new APK that works 24/7!"
echo ""

echo "💡 Quick Vercel Deployment:"
echo "   1. npm i -g vercel"
echo "   2. cd token_server"
echo "   3. vercel"
echo "   4. Follow the prompts"
echo "   5. Copy the deployment URL"
