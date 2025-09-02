# SynqCast Token Server - Glitch Deployment

## Quick Deploy to Glitch

1. **Go to [Glitch.com](https://glitch.com)**
2. **Click "New Project" → "Import from GitHub"**
3. **Enter this repository URL**: `https://github.com/yourusername/synqcast-token-server`
4. **Or manually create files**:
   - Copy `server.js` content
   - Copy `package.json` content
   - Copy `glitch.json` content

## What This Server Does

- Generates LiveKit access tokens for the SynqCast app
- Handles room creation and participant authentication
- Provides REST API endpoints for token generation

## API Endpoints

- `GET /` - Server info
- `GET /health` - Health check
- `POST /token` - Generate LiveKit token

## Environment Variables

Set these in Glitch's `.env` file:
```
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
```

## Usage

Once deployed, your Flutter app will use the Glitch URL instead of localhost:
- Replace `http://localhost:3000` with `https://your-project.glitch.me`
- The server will be always online and accessible from anywhere!

## Testing

Test the deployment by visiting:
- `https://your-project.glitch.me/health` - Should return `{"status":"ok"}`
- `https://your-project.glitch.me/` - Should show server info
