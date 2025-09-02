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

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'SynqCast LiveKit Token Server',
    version: '1.0.0',
    endpoints: ['/health', '/token'],
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// For Vercel deployment, export the app
module.exports = app;

// Always start the server (for both local and cloud deployment)
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 SynqCast Token Server running on port ${port}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📡 Server ready to accept requests`);
  
  if (process.env.NODE_ENV !== 'production') {
    console.log(`💻 Accessible from your network at: http://192.168.1.55:${port}`);
    console.log('💡 Use this URL in your Flutter app for token generation');
  }
});
