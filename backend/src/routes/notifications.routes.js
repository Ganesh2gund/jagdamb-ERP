import { store } from '../store/index.js';

export default async function notificationRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getNotifications() };
  });

  fastify.put('/:id/read', async (request, reply) => {
    const updated = store.markNotificationRead(request.params.id);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Notification not found' });
    }
    return { success: true, data: updated };
  });
}
