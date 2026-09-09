import mongoose from 'mongoose';

const adminSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, trim: true },
    name: { type: String, default: 'Admin - Jagdamb Palace' },
    role: { type: String, default: 'Admin' },
    hotelName: { type: String, default: 'Hotel Jagdamb Palace' },
  },
  { timestamps: true }
);

export const Admin = mongoose.models.Admin || mongoose.model('Admin', adminSchema);
export default Admin;
