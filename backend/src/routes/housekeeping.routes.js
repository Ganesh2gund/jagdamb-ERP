import { store } from '../store/index.js';

export default async function housekeepingRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getHousekeepingTasks() };
  });

  fastify.put('/:id/status', async (request, reply) => {
    const { status } = request.body || {};
    const updated = store.updateHousekeepingTask(request.params.id, { status });
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Task not found' });
    }
    return { success: true, data: updated };
  });
}
