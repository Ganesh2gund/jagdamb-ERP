import { store } from '../store/index.js';

export default async function authRoutes(fastify, options) {
  fastify.post('/login', async (request, reply) => {
    const { email, password } = request.body || {};

    if (!email || !password) {
      return reply.code(400).send({
        success: false,
        message: 'Email and password are required',
      });
    }

    const adminUser = await store.validateAdmin(email.trim().toLowerCase(), password.trim());
    if (!adminUser) {
      return reply.code(401).send({
        success: false,
        message: 'Invalid email or password',
      });
    }

    const token = fastify.jwt.sign({
      email: adminUser.email,
      role: adminUser.role || 'Admin',
      name: adminUser.name || 'Hotel Admin',
    });

    return {
      success: true,
      token,
      user: {
        id: adminUser._id ? String(adminUser._id) : 'adm_1',
        email: adminUser.email,
        name: adminUser.name || 'Hotel Admin',
        role: adminUser.role || 'Admin',
        hotelName: adminUser.hotelName || 'Hotel Jagdamb Palace',
      },
    };
  });

  fastify.get('/me', { onRequest: [fastify.authenticate] }, async (request, reply) => {
    return {
      success: true,
      user: request.user,
    };
  });
}
