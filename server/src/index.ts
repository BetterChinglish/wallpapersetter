import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Import Prisma Client singleton
import { prisma } from './utils/prisma';

// Import Redis connection
import { connectRedis, disconnectRedis } from './utils/redis';

// Initialize Express
const app: Express = express();
const PORT = process.env.PORT || 3000;

// ===== Middleware =====
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ===== Request Logging =====
app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// ===== Health Check =====
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// ===== Import Routes =====
import authRoutes from './routes/auth';
import wallpaperRoutes from './routes/wallpapers';

// ===== API Routes =====
app.use('/api/auth', authRoutes);
app.use('/api/wallpapers', wallpaperRoutes);

// ===== 404 Handler =====
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
  });
});

// ===== Error Handler =====
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
  });
});

// ===== Start Server =====
const server = app.listen(PORT, async () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/health`);
  
  // Connect to Redis
  try {
    await connectRedis();
  } catch (err) {
    console.error('❌ Failed to connect to Redis:', err);
  }
});

// ===== Graceful Shutdown =====
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('HTTP server closed');
  });
  await prisma.$disconnect();
  await disconnectRedis();
  console.log('Prisma and Redis disconnected');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.log('HTTP server closed');
  });
  await prisma.$disconnect();
  await disconnectRedis();
  console.log('Prisma and Redis disconnected');
  process.exit(0);
});
