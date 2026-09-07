import 'dotenv/config';
import dns from 'node:dns';
try { dns.setServers(['8.8.8.8', '1.1.1.1']); } catch (_) {}
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';

import connectDB from './db/connection.js';
import { store } from './store/index.js';
import { loadHotelSettingsFromDB } from './routes/settings.routes.js';

import authRoutes from './routes/auth.routes.js';
import roomRoutes from './routes/rooms.routes.js';
import bookingRoutes from './routes/bookings.routes.js';
import guestRoutes from './routes/guests.routes.js';
import restaurantRoutes from './routes/restaurant.routes.js';
import housekeepingRoutes from './routes/housekeeping.routes.js';
import inventoryRoutes from './routes/inventory.routes.js';
import staffRoutes from './routes/staff.routes.js';
import expenseRoutes from './routes/expenses.routes.js';
import maintenanceRoutes from './routes/maintenance.routes.js';
import notificationRoutes from './routes/notifications.routes.js';
import dashboardRoutes from './routes/dashboard.routes.js';
import whatsappRoutes from './routes/whatsapp.routes.js';
import settingsRoutes from './routes/settings.routes.js';
import reportRoutes, { initReportCycle } from './routes/report.routes.js';

const fastify = Fastify({
  logger: false, // Clean console output
});

// Allow empty or blank JSON bodies gracefully without throwing FST_ERR_CTP_EMPTY_JSON_BODY
fastify.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
  try {
    const json = (body && body.trim().length > 0) ? JSON.parse(body) : {};
    done(null, json);
  } catch (err) {
    err.statusCode = 400;
    done(err, undefined);
  }
});

// Register CORS for Flutter Web, Desktop, Mobile
await fastify.register(cors, {
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  credentials: true,
});

// Register JWT
await fastify.register(jwt, {
  secret: 'hotel-erp-super-secure-secret-key-2026',
});

// Decorator to protect routes if needed
fastify.decorate('authenticate', async (request, reply) => {
  try {
    await request.jwtVerify();
  } catch (err) {
    reply.code(401).send({ success: false, message: 'Unauthorized. Please login again.' });
  }
});

// Root endpoint
fastify.get('/', async () => {
  return {
    success: true,
    message: '🏨 Hotel ERP Fastify API is running smoothly with MongoDB Atlas!',
    health: '/api/health',
    version: '1.1.0'
  };
});

// Health check endpoint
fastify.get('/api/health', async () => {
  return {
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    service: 'Hotel ERP Fastify API Server',
    database: store.isConnected() ? 'MongoDB Atlas (Connected)' : 'Local In-Memory (Fallback)',
    version: '1.1.0'
  };
});

// Register Module Routes
fastify.register(authRoutes, { prefix: '/api/auth' });
fastify.register(roomRoutes, { prefix: '/api/rooms' });
fastify.register(bookingRoutes, { prefix: '/api/bookings' });
fastify.register(guestRoutes, { prefix: '/api/guests' });
fastify.register(restaurantRoutes, { prefix: '/api/restaurant' });
fastify.register(housekeepingRoutes, { prefix: '/api/housekeeping' });
fastify.register(inventoryRoutes, { prefix: '/api/inventory' });
fastify.register(staffRoutes, { prefix: '/api/staff' });
fastify.register(expenseRoutes, { prefix: '/api/expenses' });
fastify.register(maintenanceRoutes, { prefix: '/api/maintenance' });
fastify.register(notificationRoutes, { prefix: '/api/notifications' });
fastify.register(dashboardRoutes, { prefix: '/api/dashboard' });
fastify.register(whatsappRoutes, { prefix: '/api/whatsapp' });
fastify.register(settingsRoutes, { prefix: '/api/settings' });
fastify.register(reportRoutes, { prefix: '/api/report' });

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

try {
  // Connect to MongoDB Atlas
  await connectDB();

  // Sync data store and hotel settings with MongoDB Atlas
  await store.init();
  await loadHotelSettingsFromDB();
  await initReportCycle();

  await fastify.listen({ port: PORT, host: HOST });
  console.log(`\n======================================================`);
  console.log(`🚀 Hotel ERP Fastify Server is running!`);
  console.log(`📡 Local:    http://127.0.0.1:${PORT}`);
  console.log(`🌐 Network:  http://${HOST}:${PORT}`);
  console.log(`🏥 Health:   http://127.0.0.1:${PORT}/api/health`);
  console.log(`🍃 Database: MongoDB Atlas (Cluster0)`);
  console.log(`======================================================\n`);
} catch (err) {
  fastify.log.error ? fastify.log.error(err) : console.error(err);
  process.exit(1);
}
