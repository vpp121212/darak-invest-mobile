import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import morgan from 'morgan';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

import './config/database.js';
import { securityMiddleware } from './middleware/security.js';
import { errorHandler } from './middleware/errorHandler.js';
import propertyRoutes from './routes/properties.js';
import authRoutes from './routes/auth.js';
import signupRoute from './routes/signup.js';
import userRoutes from './routes/users.js';
import agentRoutes from './routes/agents.js';
import searchRoutes from './routes/search.js';
import uploadRoutes from './routes/upload.js';
import aiRoutes from './routes/ai.js';
import notificationRoutes from './routes/notifications.js';
import propertyRequestRoutes from './routes/propertyRequests.js';
import packageRoutes from './routes/packages.js';
import myPropertyRoutes from './routes/myProperties.js';
import financeRoutes from './routes/finance.js';
import marketingRoutes from './routes/marketing.js';
import legalRoutes from './routes/legal.js';
import businessRoutes from './routes/business.js';
import marketRoutes from './routes/market.js';
import placeholderRoutes from './routes/placeholder.js';
import tileRoutes from './routes/tiles.js';
import chatRoutes from './routes/chat.js';
import adRoutes from './routes/ads.js';
import pulseRoutes from './routes/pulse.js';
import panoramaRoutes from './routes/panorama.js';
import realestateRoutes from './routes/realestate.js';

dotenv.config();

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, { cors: { origin: '*' } });

  // Body parser (must be before security middleware)
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  
  // Apply security middleware (includes helmet)
  securityMiddleware(app);
  
  // JWT authentication middleware
  app.use((req, res, next) => {
    const authHeader = req.headers['authorization'];
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      try {
        const secret = process.env.JWT_SECRET || 'default-secret-change-in-production';
        const decoded = jwt.verify(token, secret);
        req.user = decoded;
        req.session = {
          id: decoded.id,
          iat: decoded.iat,
          tokenHash: crypto.createHash('sha256').update(token).digest('hex')
        };
      } catch (err) {
        // Don't fail the request on invalid token, just continue without auth
      }
    }
    next();
  });
app.use(compression());
app.use(morgan('combined'));
app.use('/uploads', express.static(join(__dirname, '..', 'src', 'uploads')));
app.use(express.static(join(__dirname, '..', 'public')));

app.set('io', io);

app.use('/api/auth', signupRoute);
app.use('/api/auth', authRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/users', userRoutes);
app.use('/api/agents', agentRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/property-requests', propertyRequestRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/my-properties', myPropertyRoutes);
app.use('/api/finance', financeRoutes);
app.use('/api/marketing', marketingRoutes);
app.use('/api/legal', legalRoutes);
app.use('/api/business', businessRoutes);
app.use('/api/market', marketRoutes);
app.use('/api/placeholder', placeholderRoutes);
app.use('/api/tiles', tileRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/panorama', panoramaRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/pulse', pulseRoutes);
app.use('/api/realestate', realestateRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), version: '1.0.0' });
});



app.get('/api/config/mapbox', (req, res) => {
  res.json({ token: process.env.MAPBOX_TOKEN || '' });
});

app.get('/api/tunnel-url', (req, res) => {
  try {
    const url = readFileSync(join(__dirname, '..', 'tunnel-url.txt'), 'utf8').trim();
    res.json({ url });
  } catch { res.json({ url: null }); }
});

// Serve frontend for all non-API routes
app.get('/{*splat}', (req, res) => {
  res.sendFile(join(__dirname, '..', 'public', 'index.html'));
});

app.use(errorHandler);

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.on('disconnect', () => console.log('Client disconnected:', socket.id));
});

const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 API: http://localhost:${PORT}/api`);
});

export { io };
