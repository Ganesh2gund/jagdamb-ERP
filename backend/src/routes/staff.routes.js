import { store } from '../store/index.js';

export default async function staffRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getStaff() };
  });

  fastify.put('/:id/attendance', async (request, reply) => {
    const updated = store.toggleStaffAttendance(request.params.id);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Staff member not found' });
    }
    return { success: true, data: updated };
  });
}
