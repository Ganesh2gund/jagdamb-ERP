import { store } from '../store/index.js';

export default async function guestRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    const { search } = request.query || {};
    let guests = store.getGuests();
    if (search) {
      const q = search.toLowerCase();
      guests = guests.filter(g => g.name.toLowerCase().includes(q) || g.phone.includes(q));
    }
    return { success: true, count: guests.length, data: guests };
  });

  fastify.get('/:id', async (request, reply) => {
    const guest = store.getGuestById(request.params.id);
    if (!guest) {
      return reply.code(404).send({ success: false, message: 'Guest not found' });
    }
    return { success: true, data: guest };
  });

  fastify.post('/', async (request, reply) => {
    const { name, phone } = request.body || {};
    if (!name || !phone) {
      return reply.code(400).send({ success: false, message: 'Name and phone are required' });
    }
    const created = store.createGuest(request.body);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/:id', async (request, reply) => {
    const guest = store.getGuestById(request.params.id);
    if (!guest) {
      return reply.code(404).send({ success: false, message: 'Guest not found' });
    }
    Object.assign(guest, request.body);
    return { success: true, data: guest };
  });
}
