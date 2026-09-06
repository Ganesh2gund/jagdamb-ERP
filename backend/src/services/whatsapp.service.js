/**
 * WhatsApp Business Cloud API Service
 * ------------------------------------
 * Handles all WhatsApp messaging for Hotel ERP.
 * Reads credentials from hotelSettings store (set via Settings API)
 * or falls back to process.env.
 *
 * Future DB fields (when database is added):
 *   - whatsappSent: Boolean
 *   - whatsappSentAt: DateTime
 *   - whatsappMessageId: String
 *   - whatsappError: String
 *
 * API Reference: https://developers.facebook.com/docs/whatsapp/cloud-api
 */

// Lazy import to avoid circular dependency
async function getSettings() {
  const { hotelSettings } = await import('../routes/settings.routes.js');
  return hotelSettings;
}

const WHATSAPP_API_VERSION = 'v18.0';
const WHATSAPP_API_BASE = `https://graph.facebook.com/${WHATSAPP_API_VERSION}`;

/**
 * Formats phone number to WhatsApp-compatible E.164 format.
 * Assumes Indian numbers if no country code given.
 * @param {string} phone - Raw phone number
 * @returns {{ valid: boolean, formatted: string, error?: string }}
 */
export function formatPhoneNumber(phone) {
  if (!phone || typeof phone !== 'string') {
    return { valid: false, formatted: '', error: 'Phone number is required' };
  }

  // Remove all spaces, dashes, brackets
  let cleaned = phone.replace(/[\s\-().+]/g, '');

  // Must be digits only after cleaning
  if (!/^\d+$/.test(cleaned)) {
    return { valid: false, formatted: '', error: 'Phone number must contain only digits' };
  }

  // Already has country code (91XXXXXXXXXX = 12 digits, or international)
  if (cleaned.length === 12 && cleaned.startsWith('91')) {
    return { valid: true, formatted: `+${cleaned}` };
  }

  // 10-digit Indian mobile number
  if (cleaned.length === 10) {
    // Validate Indian mobile: starts with 6, 7, 8, or 9
    if (!/^[6-9]/.test(cleaned)) {
      return { valid: false, formatted: '', error: 'Invalid Indian mobile number' };
    }
    return { valid: true, formatted: `+91${cleaned}` };
  }

  // 11-digit with leading 0 (0XXXXXXXXXX)
  if (cleaned.length === 11 && cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
    return { valid: true, formatted: `+91${cleaned}` };
  }

  return {
    valid: false,
    formatted: '',
    error: `Invalid phone number length (${cleaned.length} digits). Expected 10-digit Indian number.`,
  };
}

/**
 * Builds the professional invoice message text.
 * @param {{ guestName: string, invoiceNumber: string, totalAmount: number, hotelName: string, advanceAmount?: number, balanceDue?: number }} params
 * @returns {string}
 */
export function buildInvoiceMessage({ guestName, invoiceNumber, totalAmount, hotelName, advanceAmount = 0, balanceDue = 0 }) {
  const formatAmount = (amt) => `₹${Number(amt).toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;

  let paymentLine = '';
  if (advanceAmount > 0 && balanceDue > 0) {
    paymentLine = `\n💰 Advance Paid: ${formatAmount(advanceAmount)}\n⚠️ Balance Due: ${formatAmount(balanceDue)}`;
  } else if (balanceDue <= 0) {
    paymentLine = `\n✅ Payment Status: Fully Paid`;
  }

  return (
    `Hello ${guestName},\n\n` +
    `Thank you for choosing *${hotelName}*! 🙏\n\n` +
    `Your invoice has been generated successfully.\n\n` +
    `📋 *Invoice Details:*\n` +
    `• Invoice No: *${invoiceNumber}*\n` +
    `• Total Amount: *${formatAmount(totalAmount)}*${paymentLine}\n\n` +
    `Please find your invoice details above. For any queries, please contact our reception.\n\n` +
    `Thank you for staying with us. We look forward to hosting you again! 🏨\n\n` +
    `— ${hotelName} Team`
  );
}

/**
 * Sends a WhatsApp text message with invoice details.
 * @param {{ to: string, message: string }} params
 * @returns {Promise<{ success: boolean, messageId?: string, error?: string }>}
 */
export async function sendWhatsAppTextMessage({ to, message }) {
  const settings = await getSettings();
  const accessToken = (settings.whatsappAccessToken && settings.whatsappAccessToken !== 'your_permanent_access_token_here')
    ? settings.whatsappAccessToken
    : process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneNumberId = settings.whatsappPhoneNumberId || process.env.WHATSAPP_PHONE_NUMBER_ID;

  if (!accessToken || accessToken === 'your_permanent_access_token_here') {
    return {
      success: false,
      error: 'WhatsApp API not configured. Please set WHATSAPP_ACCESS_TOKEN in .env file.',
    };
  }

  if (!phoneNumberId || phoneNumberId === 'your_phone_number_id_here') {
    return {
      success: false,
      error: 'WhatsApp Phone Number ID not configured. Please set WHATSAPP_PHONE_NUMBER_ID in .env file.',
    };
  }

  const url = `${WHATSAPP_API_BASE}/${phoneNumberId}/messages`;

  const payload = {
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to,
    type: 'text',
    text: {
      preview_url: false,
      body: message,
    },
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      const errMsg = data?.error?.message || data?.error?.error_data?.details || `WhatsApp API error: ${response.status}`;
      return { success: false, error: errMsg };
    }

    const messageId = data?.messages?.[0]?.id;
    return {
      success: true,
      messageId,
      sentAt: new Date().toISOString(),
    };
  } catch (err) {
    return {
      success: false,
      error: `Network error: ${err.message}`,
    };
  }
}

/**
 * Sends a WhatsApp message with invoice PDF as document.
 * Requires PDF to be publicly accessible via URL or uploaded as media_id.
 *
 * NOTE: Currently using text message. When file storage is added,
 * switch to document type with media_id from uploadMedia().
 *
 * @param {{ to: string, message: string, pdfUrl?: string, pdfBase64?: string, filename?: string }} params
 */
export async function sendWhatsAppDocument({ to, message, pdfUrl, filename = 'invoice.pdf' }) {
  const accessToken = process.env.WHATSAPP_ACCESS_TOKEN;
  const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;

  if (!accessToken || accessToken === 'your_permanent_access_token_here') {
    return { success: false, error: 'WhatsApp API not configured.' };
  }

  // If no public PDF URL, fall back to text message
  if (!pdfUrl) {
    return sendWhatsAppTextMessage({ to, message });
  }

  const url = `${WHATSAPP_API_BASE}/${phoneNumberId}/messages`;

  const payload = {
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to,
    type: 'document',
    document: {
      link: pdfUrl,
      caption: message,
      filename,
    },
  };

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      const errMsg = data?.error?.message || `WhatsApp API error: ${response.status}`;
      return { success: false, error: errMsg };
    }

    return {
      success: true,
      messageId: data?.messages?.[0]?.id,
      sentAt: new Date().toISOString(),
    };
  } catch (err) {
    return { success: false, error: `Network error: ${err.message}` };
  }
}
