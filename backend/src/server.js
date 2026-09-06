import 'dotenv/config';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';

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

const fastify = Fastify({
  logger: true,
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
    message: '🏨 Hotel ERP Fastify API is running smoothly!',
    health: '/api/health',
    version: '1.0.0'
  };
});

// Health check endpoint
fastify.get('/api/health', async () => {
  return {
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    service: 'Hotel ERP Fastify API Server',
    version: '1.0.1'
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

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';

try {
  await fastify.listen({ port: PORT, host: HOST });
  console.log(`\n======================================================`);
  console.log(`🚀 Hotel ERP Fastify Server is running!`);
  console.log(`📡 Local:    http://127.0.0.1:${PORT}`);
  console.log(`🌐 Network:  http://${HOST}:${PORT}`);
  console.log(`🏥 Health:   http://127.0.0.1:${PORT}/api/health`);
  console.log(`======================================================\n`);
} catch (err) {
  fastify.log.error(err);
  process.exit(1);
}
