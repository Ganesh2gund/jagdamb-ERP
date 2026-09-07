import mongoose from 'mongoose';

const guestSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    name: { type: String, required: true },
    phone: { type: String, required: true },
    email: { type: String, default: '' },
    idType: { type: String, default: 'Aadhaar' },
    idNumber: { type: String, default: '' },
    address: { type: String, default: '' },
    totalStays: { type: Number, default: 1 },
    totalSpent: { type: Number, default: 0 },
    isVip: { type: Boolean, default: false },
  },
  { timestamps: true }
);

export const Guest = mongoose.models.Guest || mongoose.model('Guest', guestSchema);
export default Guest;
