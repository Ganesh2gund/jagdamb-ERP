import mongoose from 'mongoose';

const tableSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    number: { type: String, required: true },
    capacity: { type: Number, default: 4 },
    status: { type: String, enum: ['available', 'occupied'], default: 'available' },
    currentOrderId: { type: String, default: null },
    currentBillAmount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

export const RestaurantTable = mongoose.models.RestaurantTable || mongoose.model('RestaurantTable', tableSchema);
export default RestaurantTable;
