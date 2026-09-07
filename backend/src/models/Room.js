import mongoose from 'mongoose';

const roomSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    number: { type: String, required: true, unique: true },
    floor: { type: Number, required: true },
    type: { type: String, required: true, default: 'single' },
    pricePerNight: { type: Number, required: true },
    status: {
      type: String,
      enum: ['available', 'occupied', 'reserved', 'cleaning', 'maintenance'],
      default: 'available',
    },
    amenities: { type: [String], default: [] },
    maxGuests: { type: Number, default: 2 },
    imageUrl: { type: String, default: null },
    currentGuestName: { type: String, default: null },
    currentGuestId: { type: String, default: null },
    currentBookingId: { type: String, default: null },
    checkInDate: { type: String, default: null },
    checkOutDate: { type: String, default: null },
    maintenanceNote: { type: String, default: null },
  },
  { timestamps: true }
);

export const Room = mongoose.models.Room || mongoose.model('Room', roomSchema);
export default Room;
