import mongoose from 'mongoose';

const cafeOrderItemSchema = new mongoose.Schema(
  {
    id: { type: String },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, default: 1 },
    isVeg: { type: Boolean, default: true },
  },
  { _id: false }
);

const cafeOrderSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    orderNumber: { type: String, required: true, unique: true },
    guestName: { type: String, default: 'Walk-in Guest' },
    items: { type: [cafeOrderItemSchema], default: [] },
    subtotal: { type: Number, default: 0 },
    tax: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
    isPaid: { type: Boolean, default: true },
    paymentMethod: { type: String, default: 'Cash' },
    status: { type: String, default: 'completed' },
  },
  { timestamps: true }
);

export const CafeOrder = mongoose.models.CafeOrder || mongoose.model('CafeOrder', cafeOrderSchema);
export default CafeOrder;
