import mongoose from 'mongoose';

const invoiceItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, default: 1 },
    total: { type: Number, default: 0 },
  },
  { _id: false }
);

const invoiceSchema = new mongoose.Schema(
  {
    invoiceNumber: { type: String, required: true, unique: true },
    type: { type: String, enum: ['room', 'restaurant', 'combined'], default: 'room' },
    bookingId: { type: String, default: null },
    orderId: { type: String, default: null },
    customerName: { type: String, required: true },
    customerPhone: { type: String, default: '' },
    roomInformation: {
      roomNumber: { type: String, default: '' },
      roomType: { type: String, default: '' },
      checkInDate: { type: String, default: null },
      checkOutDate: { type: String, default: null },
      nights: { type: Number, default: 1 },
      ratePerNight: { type: Number, default: 0 },
    },
    restaurantItems: { type: [invoiceItemSchema], default: [] },
    billItems: { type: [invoiceItemSchema], default: [] },
    subtotal: { type: Number, required: true, default: 0 },
    tax: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    total: { type: Number, required: true, default: 0 },
    paidAmount: { type: Number, default: 0 },
    balanceDue: { type: Number, default: 0 },
    paymentMethod: { type: String, default: 'Cash' },
    paymentStatus: { type: String, enum: ['pending', 'partial', 'paid'], default: 'paid' },
    dateTime: { type: String, default: () => new Date().toISOString() },
  },
  { timestamps: true }
);

export const Invoice = mongoose.models.Invoice || mongoose.model('Invoice', invoiceSchema);
export default Invoice;
