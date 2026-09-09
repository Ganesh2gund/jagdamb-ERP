import mongoose from 'mongoose';

const creditPaymentSchema = new mongoose.Schema(
  {
    amount: { type: Number, required: true },
    paymentMethod: { type: String, default: 'Cash' },
    paidAt: { type: Date, default: Date.now },
    notes: { type: String, default: '' },
  },
  { _id: false }
);

const creditKhataSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true },
    billNumber: { type: String, required: true, unique: true },
    customerName: { type: String, required: true },
    customerPhone: { type: String, required: true },
    description: { type: String, default: 'Food & Dining Credit' },
    totalAmount: { type: Number, required: true, default: 0 },
    paidAmount: { type: Number, default: 0 },
    balanceAmount: { type: Number, default: 0 },
    status: { type: String, default: 'pending', enum: ['pending', 'partially_paid', 'paid'] },
    payments: { type: [creditPaymentSchema], default: [] },
  },
  { timestamps: true }
);

export const CreditKhata = mongoose.models.CreditKhata || mongoose.model('CreditKhata', creditKhataSchema);
export default CreditKhata;
