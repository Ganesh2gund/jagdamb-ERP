import mongoose from 'mongoose';

const settingsSchema = new mongoose.Schema(
  {
    hotelName: { type: String, default: 'The Grand Palace Hotel' },
    hotelPhone: { type: String, default: '' },
    hotelEmail: { type: String, default: '' },
    hotelAddress: { type: String, default: 'Near Central Station, Luxury Suites & Rooms' },
    gstNumber: { type: String, default: '' },
  },
  { timestamps: true }
);

export const Settings = mongoose.models.Settings || mongoose.model('Settings', settingsSchema);
export default Settings;
