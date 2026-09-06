import { store } from '../store/index.js';

export default async function expenseRoutes(fastify, options) {
  fastify.get('/', async (request, reply) => {
    return { success: true, data: store.getExpenses() };
  });

  fastify.post('/', async (request, reply) => {
    const { category, amount, description } = request.body || {};
    if (!category || !amount) {
      return reply.code(400).send({ success: false, message: 'Category and amount are required' });
    }
    const created = store.addExpense(request.body);
    return reply.code(201).send({ success: true, data: created });
  });

  fastify.put('/:id', async (request, reply) => {
    const updated = store.updateExpense(request.params.id, request.body || {});
    return { success: true, data: updated };
  });

  fastify.delete('/:id', async (request, reply) => {
    store.deleteExpense(request.params.id);
    return { success: true, message: 'Expense deleted successfully' };
  });
}
