/**
 * 10-Day Report & Data Lifecycle Management Routes
 * ------------------------------------------------
 * Handles:
 * - 10-day cycle tracking
 * - PDF report data generation
 * - 6-hour delayed automatic data cleanup after download
 * - Manual instant data deletion
 * - Preserving master data (Rooms, Menu, Categories, Tables, Inventory, Settings)
 */

import {
  Booking,
  RestaurantOrder,
  Expense,
  Guest,
  Notification,
  Room,
  Settings,
  ReportCycle,
} from '../models/index.js';
import { store } from '../store/index.js';
import { hotelSettings } from './settings.routes.js';
import { SupabaseMasterService } from '../services/supabaseService.js';
import mongoose from 'mongoose';

// Active in-memory cycle cache
let currentCycle = {
  cycleNumber: 1,
  startDate: new Date(),
  cleanupScheduledAt: null,
  isCleanupActive: false,
};

// Periodic timer to execute 6-hour delayed cleanup when due
let cleanupCheckInterval = null;

export async function initReportCycle() {
  if (mongoose.connection.readyState !== 1) return;

  try {
    let cycle = await ReportCycle.findOne().sort({ createdAt: -1 });
    if (!cycle) {
      cycle = await ReportCycle.create({
        cycleNumber: 1,
        startDate: new Date(),
        cleanupScheduledAt: null,
        isCleanupActive: false,
      });
      console.log('✅ Initialized 10-Day Report Cycle #1 in MongoDB Atlas.');
    }

    currentCycle = {
      cycleNumber: cycle.cycleNumber || 1,
      startDate: cycle.startDate || new Date(),
      cleanupScheduledAt: cycle.cleanupScheduledAt || null,
      isCleanupActive: cycle.isCleanupActive || false,
    };

    // Start background watcher (checks every 60 seconds if 6-hour delay expired)
    if (!cleanupCheckInterval) {
      cleanupCheckInterval = setInterval(async () => {
        if (currentCycle.isCleanupActive && currentCycle.cleanupScheduledAt) {
          const now = new Date();
          if (now >= new Date(currentCycle.cleanupScheduledAt)) {
            console.log('⏰ 6-Hour timer completed! Executing scheduled data cleanup...');
            await performDataCleanup('6-Hour Delayed Automatic Cleanup');
          }
        }
      }, 60000);
    }
  } catch (err) {
    console.error('Error initializing ReportCycle:', err.message);
  }
}

// Data cleanup function (Deletes ONLY transactional data, keeps master data)
export async function performDataCleanup(reason = 'Manual/Scheduled Cleanup') {
  try {
    console.log(`🧹 Performing Data Cleanup (${reason})...`);

    // 1. Delete transactional records from MongoDB
    if (mongoose.connection.readyState === 1) {
      await Booking.deleteMany({});
      await RestaurantOrder.deleteMany({});
      await Expense.deleteMany({});
      await Guest.deleteMany({});
      await Notification.deleteMany({});

      // Reset occupied room status back to available
      await Room.updateMany({}, {
        status: 'available',
        currentGuestName: null,
        currentGuestId: null,
        currentBookingId: null,
        checkInDate: null,
        checkOutDate: null,
      });

      // Advance cycle
      currentCycle.cycleNumber += 1;
      currentCycle.startDate = new Date();
      currentCycle.cleanupScheduledAt = null;
      currentCycle.isCleanupActive = false;

      await ReportCycle.create({
        cycleNumber: currentCycle.cycleNumber,
        startDate: currentCycle.startDate,
        cleanupScheduledAt: null,
        isCleanupActive: false,
        lastCleanupAt: new Date(),
      });
    }

    // 2. Reset in-memory cache arrays in store
    store.data.bookings = [];
    store.data.restaurantOrders = [];
    store.data.expenses = [];
    store.data.guests = [];
    store.data.notifications = [];

    // Reset rooms in memory and sync availability to Supabase (Master definitions stay permanent)
    for (const r of store.data.rooms) {
      r.status = 'available';
      delete r.currentGuestName;
      delete r.currentGuestId;
      delete r.currentBookingId;
      delete r.checkInDate;
      delete r.checkOutDate;
      SupabaseMasterService.saveRoom(r).catch(() => {});
    }

    // Reset tables in memory and sync to Supabase
    for (const t of (store.data.restaurantTables || [])) {
      t.status = 'available';
      t.currentOrderId = null;
      t.currentBillAmount = 0;
      SupabaseMasterService.saveTable(t).catch(() => {});
    }

    console.log('✅ Transactional data successfully cleaned from MongoDB! Master data in Supabase (Rooms, Menu, Tables, Settings) is 100% preserved.');
    return true;
  } catch (err) {
    console.error('❌ Data cleanup error:', err.message);
    return false;
  }
}

export default async function reportRoutes(fastify) {
  /**
   * GET /api/report/status
   * Returns current 10-day cycle status, remaining days, timer status, and revenue summary
   */
  fastify.get('/status', async (request, reply) => {
    const now = new Date();
    const startDate = new Date(currentCycle.startDate);
    const diffMs = now - startDate;
    const daysElapsed = Math.max(1, Math.floor(diffMs / (1000 * 60 * 60 * 24)) + 1);
    const daysRemaining = Math.max(0, 10 - daysElapsed);
    const isReady = daysElapsed >= 10;

    let cleanupRemainingMinutes = 0;
    if (currentCycle.isCleanupActive && currentCycle.cleanupScheduledAt) {
      const remainingMs = new Date(currentCycle.cleanupScheduledAt) - now;
      cleanupRemainingMinutes = Math.max(0, Math.floor(remainingMs / (1000 * 60)));
    }

    // Financial calculations
    const bookings = store.getBookings();
    const orders = store.getOrders();
    const expenses = store.getExpenses();

    const roomRevenue = bookings.reduce((sum, b) => sum + (Number(b.paidAmount) || Number(b.advancePaid) || 0), 0);
    const restaurantRevenue = orders.filter(o => o.isPaid).reduce((sum, o) => sum + (Number(o.total) || 0), 0);
    const totalRevenue = roomRevenue + restaurantRevenue;
    const totalExpenses = expenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);
    const netProfit = totalRevenue - totalExpenses;

    const endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 9);

    return reply.send({
      success: true,
      data: {
        cycleNumber: currentCycle.cycleNumber,
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
        daysElapsed,
        daysRemaining,
        isReady,
        isCleanupActive: currentCycle.isCleanupActive,
        cleanupScheduledAt: currentCycle.cleanupScheduledAt,
        cleanupRemainingMinutes,
        summary: {
          roomRevenue,
          restaurantRevenue,
          totalRevenue,
          totalExpenses,
          netProfit,
          totalBookingsCount: bookings.length,
          totalOrdersCount: orders.length,
          totalExpensesCount: expenses.length,
        },
      },
    });
  });

  /**
   * GET /api/report/data
   * Returns full detailed data for PDF report generation
   */
  fastify.get('/data', async (request, reply) => {
    const startDate = new Date(currentCycle.startDate);
    const endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 9);

    const bookings = store.getBookings().map(b => ({
      id: b.id,
      bookingNumber: b.bookingNumber || b.id,
      guestName: b.guestName || 'Guest',
      guestPhone: b.guestPhone || '',
      roomNumber: b.roomNumber || b.roomId || '',
      checkInDate: b.checkInDate || '',
      checkOutDate: b.checkOutDate || '',
      totalAmount: Number(b.totalAmount) || 0,
      paidAmount: Number(b.paidAmount) || Number(b.advancePaid) || 0,
      status: b.status || 'confirmed',
      paymentMethod: b.paymentMethod || 'Cash',
    }));

    const orders = store.getOrders().map(o => ({
      id: o.id,
      orderNumber: o.orderNumber || o.id,
      type: o.type || 'dineIn',
      target: o.target || 'Counter',
      guestName: o.guestName || 'Walk-in',
      items: (o.items || []).map(it => `${it.name} x${it.quantity} (₹${it.price})`).join(', '),
      total: Number(o.total) || 0,
      isPaid: o.isPaid === true,
      paymentMethod: o.paymentMethod || 'Cash',
      createdAt: o.createdAt || '',
    }));

    const expenses = store.getExpenses().map(e => ({
      id: e.id,
      date: e.date || '',
      category: e.category || 'Other',
      description: e.description || e.title || '',
      amount: Number(e.amount) || 0,
      paymentMethod: e.paymentMethod || 'Cash',
    }));

    const roomRevenue = bookings.reduce((sum, b) => sum + b.paidAmount, 0);
    const restaurantRevenue = orders.filter(o => o.isPaid).reduce((sum, o) => sum + o.total, 0);
    const totalRevenue = roomRevenue + restaurantRevenue;
    const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0);
    const netProfit = totalRevenue - totalExpenses;

    return reply.send({
      success: true,
      data: {
        hotel: {
          name: hotelSettings.hotelName,
          phone: hotelSettings.hotelPhone,
          email: hotelSettings.hotelEmail,
          address: hotelSettings.hotelAddress,
        },
        period: {
          cycleNumber: currentCycle.cycleNumber,
          startDate: startDate.toISOString().split('T')[0],
          endDate: endDate.toISOString().split('T')[0],
        },
        summary: {
          roomRevenue,
          restaurantRevenue,
          totalRevenue,
          totalExpenses,
          netProfit,
          bookingsCount: bookings.length,
          ordersCount: orders.length,
          expensesCount: expenses.length,
        },
        bookings,
        orders,
        expenses,
      },
    });
  });

  /**
   * POST /api/report/schedule-cleanup
   * Called when PDF is downloaded: Starts the 6-hour delay countdown
   */
  fastify.post('/schedule-cleanup', async (request, reply) => {
    const scheduledAt = new Date(Date.now() + 6 * 3600 * 1000); // 6 hours from now

    currentCycle.cleanupScheduledAt = scheduledAt;
    currentCycle.isCleanupActive = true;

    if (mongoose.connection.readyState === 1) {
      await ReportCycle.updateOne(
        { cycleNumber: currentCycle.cycleNumber },
        { cleanupScheduledAt: scheduledAt, isCleanupActive: true, lastDownloadedAt: new Date() }
      ).catch(e => console.error('Error updating cleanup timer in Mongo:', e.message));
    }

    return reply.send({
      success: true,
      message: 'PDF report downloaded! Data cleanup scheduled after 6 hours.',
      cleanupScheduledAt: scheduledAt.toISOString(),
      remainingMinutes: 360,
    });
  });

  /**
   * POST /api/report/cancel-cleanup
   * Cancels the 6-hour timer if admin wants to keep data
   */
  fastify.post('/cancel-cleanup', async (request, reply) => {
    currentCycle.cleanupScheduledAt = null;
    currentCycle.isCleanupActive = false;

    if (mongoose.connection.readyState === 1) {
      await ReportCycle.updateOne(
        { cycleNumber: currentCycle.cycleNumber },
        { cleanupScheduledAt: null, isCleanupActive: false }
      ).catch(e => console.error('Error cancelling cleanup timer in Mongo:', e.message));
    }

    return reply.send({
      success: true,
      message: 'Cleanup timer cancelled successfully. All data remains safe.',
    });
  });

  /**
   * POST /api/report/instant-delete
   * Manual instant deletion: Immediately purges transactional data and resets cycle
   */
  fastify.post('/instant-delete', async (request, reply) => {
    const success = await performDataCleanup('Manual Instant Deletion by Admin');
    if (success) {
      return reply.send({
        success: true,
        message: 'All transactional data (bookings, orders, expenses) deleted immediately. Master data is safe. New cycle started!',
        newCycleNumber: currentCycle.cycleNumber,
      });
    } else {
      return reply.code(500).send({
        success: false,
        message: 'Failed to delete data. Please try again.',
      });
    }
  });
}
