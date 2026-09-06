import { store } from '../store/index.js';

export default async function maintenanceRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getMaintenance() };
  });

  fastify.post('/', async (request, reply) => {
    const { roomNumber, issue } = request.body || {};
    if (!roomNumber || !issue) {
      return reply.code(400).send({ success: false, message: 'Room number and issue are required' });
    }
    const created = store.addMaintenance(request.body);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/:id', async (request, reply) => {
    const updated = store.updateMaintenance(request.params.id, request.body);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Maintenance record not found' });
    }
    return { success: true, data: updated };
  });
}
