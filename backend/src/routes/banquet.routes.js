import { store } from '../store/index.js';

export default async function banquetRoutes(fastify) {
  // ── Halls ─────────────────────────────────────────
  fastify.get('/halls', async (request, reply) => {
    return reply.send({ success: true, halls: store.getBanquetHalls() });
  });

  fastify.post('/halls', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.name) {
      return reply.code(400).send({ success: false, error: 'Hall name is required' });
    }
    const created = store.addBanquetHall(payload);
    return reply.code(201).send({ success: true, hall: created });
  });

  fastify.put('/halls/:id', async (request, reply) => {
    const { id } = request.params;
    const updates = request.body || {};
    const updated = store.updateBanquetHall(id, updates);
    if (!updated) {
      return reply.code(404).send({ success: false, error: 'Hall not found' });
    }
    return reply.send({ success: true, hall: updated });
  });

  fastify.delete('/halls/:id', async (request, reply) => {
    const { id } = request.params;
    const ok = store.deleteBanquetHall(id);
    return reply.send({ success: ok });
  });

  // ── Packages ──────────────────────────────────────
  fastify.get('/packages', async (request, reply) => {
    return reply.send({ success: true, packages: store.getBanquetPackages() });
  });

  fastify.post('/packages', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.name) {
      return reply.code(400).send({ success: false, error: 'Package name is required' });
    }
    const created = store.addBanquetPackage(payload);
    return reply.code(201).send({ success: true, package: created });
  });

  fastify.delete('/packages/:id', async (request, reply) => {
    const { id } = request.params;
    const ok = store.deleteBanquetPackage(id);
    return reply.send({ success: ok });
  });

  // Check slot availability for hall on a specific date
  fastify.get('/availability', async (request, reply) => {
    const { hallId, eventDate } = request.query || {};
    if (!hallId || !eventDate) {
      return reply.code(400).send({ success: false, error: 'hallId and eventDate are required' });
    }
    const availability = store.getBanquetSlotAvailability(hallId, eventDate);
    return reply.send({ success: true, availability });
  });

  // ── Bookings ──────────────────────────────────────
  fastify.get('/bookings', async (request, reply) => {
    return reply.send({ success: true, bookings: store.getBanquetBookings() });
  });

  fastify.get('/bookings/:id', async (request, reply) => {
    const { id } = request.params;
    const booking = store.getBanquetBookingById(id);
    if (!booking) {
      return reply.code(404).send({ success: false, error: 'Booking not found' });
    }
    return reply.send({ success: true, booking });
  });

  fastify.post('/bookings', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.customerName || !payload.eventDate || !payload.hallId) {
      return reply.code(400).send({ success: false, error: 'Customer name, event date, and hall are required' });
    }
    try {
      const created = store.createBanquetBooking(payload);
      return reply.code(201).send({ success: true, booking: created });
    } catch (err) {
      return reply.code(409).send({ success: false, error: err.message });
    }
  });

  fastify.put('/bookings/:id', async (request, reply) => {
    const { id } = request.params;
    const updates = request.body || {};
    const updated = store.updateBanquetBooking(id, updates);
    if (!updated) {
      return reply.code(404).send({ success: false, error: 'Booking not found' });
    }
    return reply.send({ success: true, booking: updated });
  });

  fastify.delete('/bookings/:id', async (request, reply) => {
    const { id } = request.params;
    const permanent = request.query?.permanent === 'true' || request.query?.permanent === true;
    if (permanent) {
      const ok = store.deleteBanquetBooking(id);
      return reply.send({ success: ok, message: ok ? 'Booking deleted permanently' : 'Booking not found' });
    }
    const reason = request.query?.reason || 'Cancelled by admin';
    const cancelled = store.cancelBanquetBooking(id, reason);
    if (!cancelled) {
      return reply.code(404).send({ success: false, error: 'Booking not found' });
    }
    return reply.send({ success: true, booking: cancelled });
  });
}
