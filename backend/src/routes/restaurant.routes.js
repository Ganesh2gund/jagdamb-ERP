import { store } from '../store/index.js';

export default async function restaurantRoutes(fastify, options) {
  // ── Menu Routes ────────────────────────────────
  fastify.get('/menu', async (request, reply) => {
    return { success: true, data: store.getMenu() };
  });

  fastify.post('/menu', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.name || payload.price === undefined) {
      return reply.code(400).send({ success: false, message: 'Name and price are required' });
    }
    const created = store.addMenuItem(payload);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/menu/:id', async (request, reply) => {
    const updated = store.updateMenuItem(request.params.id, request.body || {});
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Menu item not found' });
    }
    return { success: true, data: updated };
  });

  fastify.delete('/menu/:id', async (request, reply) => {
    const ok = store.deleteMenuItem(request.params.id);
    if (!ok) {
      return reply.code(404).send({ success: false, message: 'Menu item not found' });
    }
    return { success: true, message: 'Menu item deleted' };
  });

  // ── Categories Routes ──────────────────────────
  fastify.get('/categories', async (request, reply) => {
    return { success: true, data: store.getCategories() };
  });

  fastify.post('/categories', async (request, reply) => {
    const { name } = request.body || {};
    if (!name || !name.trim()) {
      return reply.code(400).send({ success: false, message: 'Category name is required' });
    }
    const created = store.addCategory(name);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.delete('/categories/:name', async (request, reply) => {
    const ok = store.deleteCategory(decodeURIComponent(request.params.name));
    if (!ok) {
      return reply.code(404).send({ success: false, message: 'Category not found' });
    }
    return { success: true, message: 'Category deleted' };
  });

  // ── Tables Routes ──────────────────────────────
  fastify.get('/tables', async (request, reply) => {
    return { success: true, data: store.getTables() };
  });

  fastify.post('/tables', async (request, reply) => {
    const { number, capacity } = request.body || {};
    if (!number) {
      return reply.code(400).send({ success: false, message: 'Table number is required' });
    }
    const created = store.createTable({ number, capacity: capacity || 4 });
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/tables/:id', async (request, reply) => {
    const updated = store.updateTable(request.params.id, request.body || {});
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Table not found' });
    }
    return { success: true, data: updated };
  });

  fastify.delete('/tables/:id', async (request, reply) => {
    const ok = store.deleteTable(request.params.id);
    if (!ok) {
      return reply.code(404).send({ success: false, message: 'Table not found' });
    }
    return { success: true, message: 'Table deleted successfully' };
  });

  fastify.put('/tables/:id/status', async (request, reply) => {
    const { status, currentOrderId, currentBillAmount } = request.body || {};
    const updated = store.updateTableStatus(request.params.id, status, currentOrderId, currentBillAmount);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Table not found' });
    }
    return { success: true, data: updated };
  });

  // ── Orders Routes ──────────────────────────────
  fastify.get('/orders', async (request, reply) => {
    const orders = store.getOrders();
    for (const o of orders) {
      if (o.items && o.items.length) {
        const itemSum = o.items.reduce((sum, it) => sum + ((Number(it.price) || 0) * (Number(it.quantity) || 1)), 0);
        if (itemSum > 0 && Math.abs(o.total - itemSum) > 0.001) {
          // Fix previous order where 5% tax was automatically added
          o.total = itemSum;
          o.subtotal = itemSum;
          o.tax = 0;
        }
      }
    }
    return { success: true, data: orders };
  });

  fastify.post('/orders', async (request, reply) => {
    const { items, type, target, guestName, isPaid, paymentMethod } = request.body || {};
    if (!items || !items.length) {
      return reply.code(400).send({ success: false, message: 'Items are required' });
    }

    const subtotal = items.reduce((sum, it) => sum + ((Number(it.price) || 0) * (Number(it.quantity) || 1)), 0);
    const total = request.body?.total !== undefined ? Number(request.body.total) : subtotal;

    const order = store.createOrder({
      type: type || 'dineIn',
      target: target || 'Counter',
      guestName: guestName || null,
      items,
      subtotal,
      tax: 0,
      total,
      isPaid: isPaid || false,
      paymentMethod: paymentMethod || null,
    });

    return reply.code(201).send({ success: true, data: order });
  });

  fastify.put('/orders/:id/status', async (request, reply) => {
    const { status } = request.body || {};
    const updated = store.updateOrderStatus(request.params.id, status);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Order not found' });
    }
    return { success: true, data: updated };
  });

  // Settle Walk-in / Table Order (अलग से बिल)
  fastify.post('/orders/:id/settle', async (request, reply) => {
    const { paymentMethod, grandTotal } = request.body || {};
    const settled = store.settleOrder(request.params.id, paymentMethod, 0, grandTotal);
    if (!settled) {
      return reply.code(404).send({ success: false, message: 'Order not found' });
    }
    return { success: true, message: 'Order settled successfully and table cleared', data: settled };
  });
}
