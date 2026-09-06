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

    const isValid = store.validateAdmin(email.trim().toLowerCase(), password.trim());
    if (!isValid) {
      return reply.code(401).send({
        success: false,
        message: 'Invalid email or password. Use tejas@gmail.com / tejas4010',
      });
    }

    const token = fastify.jwt.sign({
      email: 'tejas@gmail.com',
      role: 'Admin',
      name: 'Tejas (Hotel Admin)',
    });

    return {
      success: true,
      token,
      user: {
        id: 'adm_1',
        email: 'tejas@gmail.com',
        name: 'Tejas (Hotel Admin)',
        role: 'Admin',
        hotelName: 'Grand Horizon Luxury Hotel & Suites',
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
