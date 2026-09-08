import mongoose from 'mongoose';

const cafeCategorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true },
  },
  { timestamps: true }
);

export const CafeCategory = mongoose.models.CafeCategory || mongoose.model('CafeCategory', cafeCategorySchema);
export default CafeCategory;
