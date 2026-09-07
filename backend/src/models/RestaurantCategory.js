import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true },
  },
  { timestamps: true }
);

export const RestaurantCategory = mongoose.models.RestaurantCategory || mongoose.model('RestaurantCategory', categorySchema);
export default RestaurantCategory;
