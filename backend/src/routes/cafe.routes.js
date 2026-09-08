import { store } from '../store/index.js';

export default async function cafeRoutes(fastify, options) {
  // ── Cafe Menu Routes ───────────────────────────
  fastify.get('/menu', async (request, reply) => {
    return { success: true, data: store.getCafeMenu() };
  });

  fastify.post('/menu', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.name || payload.price === undefined) {
      return reply.code(400).send({ success: false, message: 'Name and price are required' });
    }
    const created = store.addCafeMenuItem(payload);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/menu/:id', async (request, reply) => {
    const updated = store.updateCafeMenuItem(request.params.id, request.body || {});
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Cafe item not found' });
    }
    return { success: true, data: updated };
  });

  fastify.delete('/menu/:id', async (request, reply) => {
    const ok = store.deleteCafeMenuItem(request.params.id);
    if (!ok) {
      return reply.code(404).send({ success: false, message: 'Cafe item not found' });
    }
    return { success: true, message: 'Cafe item deleted' };
  });

  // ── Cafe Categories Routes ─────────────────────
  fastify.get('/categories', async (request, reply) => {
    return { success: true, data: store.getCafeCategories() };
  });

  fastify.post('/categories', async (request, reply) => {
    const { name } = request.body || {};
    if (!name || !name.trim()) {
      return reply.code(400).send({ success: false, message: 'Category name is required' });
    }
    const created = store.addCafeCategory(name);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.delete('/categories/:name', async (request, reply) => {
    const ok = store.deleteCafeCategory(decodeURIComponent(request.params.name));
    if (!ok) {
      return reply.code(404).send({ success: false, message: 'Category not found' });
    }
    return { success: true, message: 'Category deleted' };
  });

  // ── Cafe Orders & Billing Routes ───────────────
  fastify.get('/orders', async (request, reply) => {
    return { success: true, data: store.getCafeOrders() };
  });

  fastify.post('/orders', async (request, reply) => {
    const { items, guestName, isPaid, paymentMethod, total } = request.body || {};
    if (!items || !items.length) {
      return reply.code(400).send({ success: false, message: 'Items are required' });
    }

    const order = store.createCafeOrder({
      guestName: guestName || 'Walk-in Guest',
      items,
      total,
      isPaid: isPaid !== undefined ? isPaid : true,
      paymentMethod: paymentMethod || 'Cash',
    });

    return reply.code(201).send({ success: true, data: order });
  });
}
