import { store } from '../store/index.js';

export default async function creditRoutes(fastify) {
  /**
   * GET /api/credit
   * Returns all credit bills and summary statistics
   */
  fastify.get('/', async (request, reply) => {
    const credits = store.getCreditKhatas();

    const totalUdhaar = credits.reduce((sum, c) => sum + (Number(c.totalAmount) || 0), 0);
    const totalRecovered = credits.reduce((sum, c) => sum + (Number(c.paidAmount) || 0), 0);
    const totalOutstanding = credits.reduce((sum, c) => sum + (Number(c.balanceAmount) || 0), 0);
    const pendingCount = credits.filter(c => c.status !== 'paid').length;
    const paidCount = credits.filter(c => c.status === 'paid').length;

    return reply.send({
      success: true,
      credits,
      summary: {
        totalUdhaar,
        totalRecovered,
        totalOutstanding,
        totalCount: credits.length,
        pendingCount,
        paidCount,
      },
    });
  });

  /**
   * GET /api/credit/:id
   * Get single credit bill by ID or Bill Number
   */
  fastify.get('/:id', async (request, reply) => {
    const { id } = request.params;
    const credit = store.getCreditKhataById(id);
    if (!credit) {
      return reply.code(404).send({ success: false, error: 'Credit bill not found' });
    }
    return reply.send({ success: true, credit });
  });

  /**
   * POST /api/credit
   * Create a new standalone Credit / Udhaar Bill
   */
  fastify.post('/', async (request, reply) => {
    const payload = request.body || {};
    if (!payload.customerName || !payload.customerName.trim()) {
      return reply.code(400).send({ success: false, error: 'Customer name is required' });
    }
    if (!payload.customerPhone || !payload.customerPhone.trim()) {
      return reply.code(400).send({ success: false, error: 'Customer phone number is required' });
    }
    const totalAmount = Number(payload.totalAmount);
    if (isNaN(totalAmount) || totalAmount <= 0) {
      return reply.code(400).send({ success: false, error: 'Please enter a valid total amount' });
    }

    try {
      const created = store.createCreditKhata(payload);
      return reply.code(201).send({
        success: true,
        message: 'Credit bill generated successfully',
        credit: created,
      });
    } catch (err) {
      return reply.code(500).send({ success: false, error: err.message });
    }
  });

  /**
   * POST /api/credit/:id/pay
   * Record payment (full or partial) against a credit bill
   */
  fastify.post('/:id/pay', async (request, reply) => {
    const { id } = request.params;
    const payload = request.body || {};
    const amount = Number(payload.amount);

    if (isNaN(amount) || amount <= 0) {
      return reply.code(400).send({ success: false, error: 'Please enter a valid payment amount' });
    }

    const updated = store.recordCreditPayment(id, {
      amount,
      paymentMethod: payload.paymentMethod || 'Cash',
      notes: payload.notes || '',
    });

    if (!updated) {
      return reply.code(404).send({ success: false, error: 'Credit bill not found' });
    }

    return reply.send({
      success: true,
      message: updated.status === 'paid' ? 'Credit bill cleared in FULL!' : 'Payment recorded successfully',
      credit: updated,
    });
  });

  /**
   * DELETE /api/credit/:id
   * Admin manual deletion
   */
  fastify.delete('/:id', async (request, reply) => {
    const { id } = request.params;
    const ok = store.deleteCreditKhata(id);
    if (!ok) {
      return reply.code(404).send({ success: false, error: 'Credit bill not found' });
    }
    return reply.send({ success: true, message: 'Credit bill deleted successfully' });
  });
}
