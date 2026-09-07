import mongoose from 'mongoose';

const inventorySchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    name: { type: String, required: true },
    category: { type: String, default: 'General' },
    currentStock: { type: Number, default: 0 },
    minStock: { type: Number, default: 5 },
    unit: { type: String, default: 'pcs' },
    isLowStock: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export const Inventory = mongoose.models.Inventory || mongoose.model('Inventory', inventorySchema);
export default Inventory;
