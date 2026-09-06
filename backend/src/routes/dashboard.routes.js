import { store } from '../store/index.js';

export default async function dashboardRoutes(fastify, options) {
  fastify.get('/summary', async (request, reply) => {
    return {
      success: true,
      data: store.getDashboardSummary(),
    };
  });
}
