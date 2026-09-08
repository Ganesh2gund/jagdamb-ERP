import mongoose from 'mongoose';

const banquetBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingNumber: { type: String, required: true, index: true },
    hallId: { type: String, required: true },
    hallName: { type: String, required: true },
    customerName: { type: String, required: true },
    customerPhone: { type: String, required: true },
    customerEmail: { type: String, default: '' },
    eventType: { type: String, default: 'Wedding' }, // Wedding, Birthday, Corporate, Reception, Anniversary, Other
    eventDate: { type: String, required: true, index: true }, // YYYY-MM-DD
    slot: { type: String, default: 'Evening' }, // Morning, Evening, Full Day
    expectedGuests: { type: Number, default: 100 },
    packageId: { type: String, default: '' },
    packageName: { type: String, default: '' },
    pricePerPlate: { type: Number, default: 0 },
    foodTotal: { type: Number, default: 0 },
    hallRent: { type: Number, default: 0 },
    extraCharges: { type: Number, default: 0 }, // Decoration, sound/DJ, lights
    tax: { type: Number, default: 0 },
    grandTotal: { type: Number, default: 0 },
    advancePaid: { type: Number, default: 0 },
    balanceDue: { type: Number, default: 0 },
    status: { type: String, default: 'confirmed' }, // confirmed, completed, cancelled
    notes: { type: String, default: '' },
  },
  { timestamps: true }
);

export const BanquetBooking = mongoose.models.BanquetBooking || mongoose.model('BanquetBooking', banquetBookingSchema);
export default BanquetBooking;
