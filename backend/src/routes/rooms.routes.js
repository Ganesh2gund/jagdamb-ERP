import { store } from '../store/index.js';

export default async function roomRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    const { status, checkIn, checkOut } = request.query || {};
    let rooms = store.getRooms();

    // If checkIn and checkOut dates are provided, filter rooms by date-range availability
    if (checkIn && checkOut) {
      rooms = store.getAvailableRoomsForDates(checkIn, checkOut);
    }

    if (status) {
      rooms = rooms.filter(r => r.status.toLowerCase() === status.toLowerCase());
    }
    return { success: true, count: rooms.length, data: rooms };
  });

  fastify.get('/:id', async (request, reply) => {
    const room = store.getRoomById(request.params.id);
    if (!room) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    return { success: true, data: room };
  });

  fastify.put('/:id/status', async (request, reply) => {
    const { status, maintenanceNote } = request.body || {};
    const updated = store.updateRoomStatus(request.params.id, status, maintenanceNote);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    return { success: true, data: updated };
  });

  fastify.post('/:id/clean', async (request, reply) => {
    const updated = store.markRoomCleaned(request.params.id);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    return { success: true, data: updated, message: 'Room marked as cleaned and available' };
  });

  fastify.post('/:id/checkin', async (request, reply) => {
    const { guestId, guestName, bookingId, checkInDate, checkOutDate } = request.body || {};
    const updated = store.checkInRoom(
      request.params.id,
      guestId,
      guestName,
      bookingId,
      checkInDate || new Date().toISOString(),
      checkOutDate
    );
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    return { success: true, data: updated };
  });

  fastify.post('/:id/checkout', async (request, reply) => {
    const updated = store.checkOutRoom(request.params.id);
    if (!updated) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    return { success: true, data: updated, message: 'Guest checked out. Room moved to cleaning.' };
  });

  // ──────────────────────────────────────
  // CREATE a new room (Admin adds room)
  // ──────────────────────────────────────
  fastify.post('/', async (request, reply) => {
    const { number, floor, type, pricePerNight, amenities, maxGuests, imageUrl } = request.body || {};

    if (!number || !floor || !type || !pricePerNight) {
      return reply.code(400).send({
        success: false,
        message: 'number, floor, type and pricePerNight are required',
      });
    }

    // Check duplicate room number
    const existing = store.getRooms().find(r => r.number === String(number));
    if (existing) {
      return reply.code(409).send({
        success: false,
        message: `Room number ${number} already exists`,
      });
    }

    const newRoom = store.createRoom({
      number: String(number),
      floor: Number(floor),
      type: type.toLowerCase(),
      pricePerNight: Number(pricePerNight),
      status: 'available',
      amenities: amenities || [],
      maxGuests: Number(maxGuests) || 2,
      imageUrl: imageUrl || null,
    });

    return reply.code(201).send({ success: true, data: newRoom });
  });

  // ──────────────────────────────────────
  // UPDATE room details (Admin edits room)
  // ──────────────────────────────────────
  fastify.put('/:id', async (request, reply) => {
    const room = store.getRoomById(request.params.id);
    if (!room) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    const updated = store.updateRoom(request.params.id, request.body || {});
    return { success: true, data: updated };
  });

  // ──────────────────────────────────────
  // DELETE a room (Admin removes room)
  // ──────────────────────────────────────
  fastify.delete('/:id', async (request, reply) => {
    const room = store.getRoomById(request.params.id);
    if (!room) {
      return reply.code(404).send({ success: false, message: 'Room not found' });
    }
    if (room.status === 'occupied') {
      return reply.code(400).send({
        success: false,
        message: 'Cannot delete an occupied room. Please check-out the guest first.',
      });
    }
    store.deleteRoom(request.params.id);
    return { success: true, message: `Room ${room.number} deleted successfully` };
  });
}
