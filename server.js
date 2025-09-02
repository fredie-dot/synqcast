const express = require('express');
const cors = require('cors');
const { AccessToken } = require('livekit-server-sdk');

const app = express();

// Enable CORS for Flutter app
app.use(cors());
app.use(express.json());

// Your LiveKit API keys (replace with your actual keys)
const API_KEY = 'devkey';
const API_SECRET = 'secret';

// Generate token endpoint
app.post('/token', (req, res) => {
  const { roomName, participantName } = req.body;
  
  if (!roomName || !participantName) {
    return res.status(400).json({ error: 'Room name and participant name are required' });
  }

  try {
    // Create access token
    const at = new AccessToken(API_KEY, API_SECRET, {
      identity: participantName,
      name: participantName,
    });

    // Grant permissions
    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    // Generate token
    const token = at.toJwt();

    res.json({ token });
  } catch (error) {
    console.error('Error generating token:', error);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// For Vercel deployment, export the app
module.exports = app;

// For local development, start the server
if (process.env.NODE_ENV !== 'production') {
  const port = process.env.PORT || 3000;
  app.listen(port, '0.0.0.0', () => {
    console.log(`Token server running on http://0.0.0.0:${port}`);
    console.log(`Accessible from your network at: http://192.168.1.55:${port}`);
    console.log('Use this URL in your Flutter app for token generation');
  });
}
