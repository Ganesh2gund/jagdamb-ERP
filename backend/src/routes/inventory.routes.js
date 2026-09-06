import { store } from '../store/index.js';

export default async function inventoryRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getInventory() };
  });

  fastify.put('/:id/stock', async (request, reply) => {
    const { currentStock } = request.body || {};
    if (currentStock === undefined) {
      return reply.code(400).send({ success: false, message: 'currentStock is required' });
    }
    const updated = store.updateInventoryStock(request.params.id, currentStock);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Item not found' });
    }
    return { success: true, data: updated };
  });
}
