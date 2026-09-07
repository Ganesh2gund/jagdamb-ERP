import mongoose from 'mongoose';

const reportCycleSchema = new mongoose.Schema(
  {
    cycleNumber: { type: Number, default: 1 },
    startDate: { type: Date, default: () => new Date() },
    cleanupScheduledAt: { type: Date, default: null },
    isCleanupActive: { type: Boolean, default: false },
    lastDownloadedAt: { type: Date, default: null },
    lastCleanupAt: { type: Date, default: null },
  },
  { timestamps: true }
);

export const ReportCycle = mongoose.models.ReportCycle || mongoose.model('ReportCycle', reportCycleSchema);
export default ReportCycle;
