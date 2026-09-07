import mongoose from 'mongoose';

const bookingSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    bookingNumber: { type: String, required: true, unique: true },
    guestName: { type: String, required: true },
    guestPhone: { type: String, default: '' },
    guestEmail: { type: String, default: '' },
    guestId: { type: String, default: null },
    roomId: { type: String, required: true },
    roomNumber: { type: String, default: '' },
    checkInDate: { type: String, default: null },
    checkOutDate: { type: String, default: null },
    totalNights: { type: Number, default: 1 },
    totalAmount: { type: Number, default: 0 },
    advancePaid: { type: Number, default: 0 },
    paidAmount: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['confirmed', 'checkedIn', 'checkedOut', 'cancelled'],
      default: 'confirmed',
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'partial', 'paid'],
      default: 'pending',
    },
    paymentMethod: { type: String, default: 'Cash' },
    cancellationReason: { type: String, default: null },
  },
  { timestamps: true }
);

export const Booking = mongoose.models.Booking || mongoose.model('Booking', bookingSchema);
export default Booking;
