import mongoose from 'mongoose';

const expenseSchema = new mongoose.Schema(
  {
    id: { type: String, unique: true, required: true },
    title: { type: String, default: '' },
    description: { type: String, default: '' },
    category: { type: String, required: true, default: 'Other' },
    amount: { type: Number, required: true },
    paymentMethod: { type: String, default: 'Cash' },
    notes: { type: String, default: null },
    date: { type: String, default: () => new Date().toISOString().split('T')[0] },
  },
  { timestamps: true }
);

export const Expense = mongoose.models.Expense || mongoose.model('Expense', expenseSchema);
export default Expense;
