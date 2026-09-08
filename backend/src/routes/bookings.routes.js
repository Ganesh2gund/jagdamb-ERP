import { store } from '../store/index.js';

export default async function bookingRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    const { status } = request.query || {};
    let bookings = store.getBookings();
    if (status) {
      bookings = bookings.filter(b => b.status.toLowerCase() === status.toLowerCase());
    }
    return { success: true, count: bookings.length, data: bookings };
  });

  fastify.get('/:id', async (request, reply) => {
    const booking = store.getBookingById(request.params.id);
    if (!booking) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    return { success: true, data: booking };
  });

  fastify.post('/', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.guestName || !payload.roomId) {
      return reply.code(400).send({ success: false, message: 'guestName and roomId are required' });
    }

    // Check date-range availability before creating booking
    if (payload.checkInDate && payload.checkOutDate) {
      const isFree = store.isRoomAvailableForDates(payload.roomId, payload.checkInDate, payload.checkOutDate);
      if (!isFree) {
        return reply.code(400).send({
          success: false,
          message: `Room is already reserved for another guest during the requested dates (${payload.checkInDate} to ${payload.checkOutDate}).`,
        });
      }
    }

    const created = store.createBooking(payload);

    // ── Auto Check-In ──────────────────────────────
    // If checkInNow flag is set, immediately check in the guest
    if (payload.checkInNow === true) {
      created.status = 'checkedIn';
      store.checkInRoom(
        created.roomId,
        created.guestId,
        created.guestName,
        created.id,
        new Date().toISOString(),
        created.checkOutDate
      );
    }
    // ───────────────────────────────────────────────

    return reply.code(201).send({ success: true, data: created });
  });

  // Extend in-house stay by +N night(s)
  fastify.post('/:id/extend', async (request, reply) => {
    const { extraNights } = request.body || {};
    const nights = Number(extraNights) || 1;
    const result = store.extendBookingStay(request.params.id, nights);
    if (!result.success) {
      return reply.code(400).send(result);
    }
    return reply.send(result);
  });

  // Update booking details (Edit)
  fastify.put('/:id', async (request, reply) => {
    const payload = request.body || {};
    const updated = store.updateBooking(request.params.id, payload);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    return { success: true, message: 'Booking updated successfully', data: updated };
  });

  // Cancel booking with reason
  fastify.post('/:id/cancel', async (request, reply) => {
    const { reason } = request.body || {};
    const cancelled = store.cancelBooking(request.params.id, reason);
    if (!cancelled) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    return { success: true, message: 'Booking cancelled successfully', data: cancelled };
  });

  fastify.put('/:id/status', async (request, reply) => {
    const { status } = request.body || {};
    const updated = store.updateBookingStatus(request.params.id, status);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    return { success: true, data: updated };
  });

  fastify.put('/:id/payment', async (request, reply) => {
    const { paymentStatus, paidAmount } = request.body || {};
    const updated = store.updateBookingPayment(request.params.id, paymentStatus, paidAmount);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    return { success: true, data: updated };
  });

  // Check-In flow
  fastify.post('/:id/check-in', async (request, reply) => {
    const booking = store.getBookingById(request.params.id);
    if (!booking) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    booking.status = 'checkedIn';
    store.checkInRoom(
      booking.roomId,
      booking.guestId,
      booking.guestName,
      booking.id,
      new Date().toISOString(),
      booking.checkOutDate
    );
    return { success: true, message: 'Checked in successfully', data: booking };
  });

  // Check-Out flow
  fastify.post('/:id/check-out', async (request, reply) => {
    const booking = store.getBookingById(request.params.id);
    if (!booking) {
      return reply.code(404).send({ success: false, message: 'Booking not found' });
    }
    booking.status = 'checkedOut';
    booking.paymentStatus = 'paid';
    store.checkOutRoom(booking.roomId);
    return { success: true, message: 'Checked out successfully', data: booking };
  });
}
