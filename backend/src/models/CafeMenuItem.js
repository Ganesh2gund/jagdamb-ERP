import mongoose from 'mongoose';

const cafeMenuItemSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    name: { type: String, required: true },
    category: { type: String, default: 'Hot Beverages' },
    price: { type: Number, required: true },
    isVeg: { type: Boolean, default: true },
    description: { type: String, default: '' },
    isAvailable: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export const CafeMenuItem = mongoose.models.CafeMenuItem || mongoose.model('CafeMenuItem', cafeMenuItemSchema);
export default CafeMenuItem;
