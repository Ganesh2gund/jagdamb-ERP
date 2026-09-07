import mongoose from 'mongoose';

const orderItemSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, default: 1 },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    orderNumber: { type: String, required: true, unique: true },
    type: { type: String, default: 'dineIn' },
    target: { type: String, default: 'Counter' },
    guestName: { type: String, default: 'Walk-in Guest' },
    bookingId: { type: String, default: null },
    roomId: { type: String, default: null },
    items: { type: [orderItemSchema], default: [] },
    subtotal: { type: Number, default: 0 },
    tax: { type: Number, default: 0 },
    total: { type: Number, default: 0 },
    isPaid: { type: Boolean, default: true },
    paymentMethod: { type: String, default: 'Cash' },
    status: { type: String, default: 'received' },
  },
  { timestamps: true }
);

export const RestaurantOrder = mongoose.models.RestaurantOrder || mongoose.model('RestaurantOrder', orderSchema);
export default RestaurantOrder;
