/**
 * WhatsApp Routes
 * ---------------
 * POST /api/whatsapp/send-invoice  — Send invoice details via WhatsApp
 * POST /api/whatsapp/validate-number — Validate & format a phone number
 */

import {
  formatPhoneNumber,
  buildInvoiceMessage,
  sendWhatsAppTextMessage,
} from '../services/whatsapp.service.js';

export default async function whatsappRoutes(fastify) {
  /**
   * POST /api/whatsapp/validate-number
   * Body: { phone: string }
   * Returns: { valid, formatted, error? }
   */
  fastify.post('/validate-number', async (request, reply) => {
    const { phone } = request.body ?? {};

    if (!phone) {
      return reply.code(400).send({ success: false, message: 'phone is required' });
    }

    const result = formatPhoneNumber(String(phone));
    return reply.send({ success: true, ...result });
  });

  /**
   * POST /api/whatsapp/send-invoice
   *
   * Body:
   * {
   *   phone: string,          // customer WhatsApp number
   *   guestName: string,
   *   invoiceNumber: string,
   *   totalAmount: number,
   *   advanceAmount?: number,
   *   balanceDue?: number,
   *   hotelName?: string,
   * }
   *
   * Returns:
   * {
   *   success: boolean,
   *   whatsappSent: boolean,         // future DB field
   *   whatsappMessageId?: string,    // future DB field
   *   whatsappSentAt?: string,       // future DB field
   *   whatsappError?: string,        // future DB field
   *   message: string,
   * }
   */
  fastify.post('/send-invoice', async (request, reply) => {
    const {
      phone,
      guestName,
      invoiceNumber,
      totalAmount,
      advanceAmount = 0,
      balanceDue = 0,
      hotelName = 'Hotel Grand ERP',
    } = request.body ?? {};

    // ── Validate required fields ──────────────────────────────────
    if (!phone || !guestName || !invoiceNumber || totalAmount == null) {
      return reply.code(400).send({
        success: false,
        whatsappSent: false,
        message: 'Missing required fields: phone, guestName, invoiceNumber, totalAmount',
      });
    }

    // ── Format phone number ───────────────────────────────────────
    const phoneResult = formatPhoneNumber(String(phone));
    if (!phoneResult.valid) {
      return reply.code(400).send({
        success: false,
        whatsappSent: false,
        message: phoneResult.error || 'Invalid phone number',
      });
    }

    // ── Build message ─────────────────────────────────────────────
    const message = buildInvoiceMessage({
      guestName,
      invoiceNumber,
      totalAmount: Number(totalAmount),
      hotelName,
      advanceAmount: Number(advanceAmount),
      balanceDue: Number(balanceDue),
    });

    // ── Send via WhatsApp ─────────────────────────────────────────
    const result = await sendWhatsAppTextMessage({
      to: phoneResult.formatted,
      message,
    });

    // ── Respond — WhatsApp failure does NOT fail the API call ────
    // Bill generation already succeeded on the client side.
    // We report the WhatsApp status separately.
    if (result.success) {
      return reply.send({
        success: true,
        whatsappSent: true,
        whatsappMessageId: result.messageId,
        whatsappSentAt: result.sentAt,
        message: `Invoice sent successfully to ${phoneResult.formatted}`,
      });
    } else {
      // Return 200 (not 5xx) — invoice exists, only WhatsApp failed
      return reply.code(200).send({
        success: false,
        whatsappSent: false,
        whatsappError: result.error,
        message: result.error || 'WhatsApp sending failed',
      });
    }
  });
}
