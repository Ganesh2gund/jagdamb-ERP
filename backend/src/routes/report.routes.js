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
  ReportCycle,
  Invoice,
  CafeOrder,
  BanquetBooking,
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
    let cycle = await ReportCycle.findOne().sort({ cycleNumber: -1, createdAt: -1 });
    if (!cycle) {
      cycle = await ReportCycle.create({
        cycleNumber: 1,
        startDate: new Date(),
        cleanupScheduledAt: null,
        isCleanupActive: false,
      });
      console.log('✅ Initialized 10-Day Report Cycle #1 in MongoDB Atlas.');
    }

    // Ensure only 1 active cycle document exists in MongoDB Atlas (prevent accumulation)
    await ReportCycle.deleteMany({ _id: { $ne: cycle._id } }).catch(() => {});

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

// Smart Data cleanup function: Cleans only past completed data, 100% PRESERVES future bookings & in-house guests
export async function performDataCleanup(reason = 'Manual/Scheduled Cleanup') {
  try {
    console.log(`🧹 Performing Smart Data Cleanup (${reason})...`);
    const todayStr = new Date().toISOString().split('T')[0];

    // 1. Transactional records cleanup from MongoDB
    if (mongoose.connection.readyState === 1) {
      // Clean only completed/checked-out or past cancelled room bookings (Keep in-house & future bookings safe)
      await Booking.deleteMany({ status: { $in: ['checkedOut', 'cancelled'] } });

      // Clean only past, completed, or cancelled banquet bookings (Keep only future/today confirmed events safe)
      await BanquetBooking.deleteMany({
        $or: [
          { eventDate: { $lt: todayStr } },
          { status: 'completed' },
          { status: 'cancelled' },
        ],
      });

      // Clean only paid restaurant orders (Keep active unpaid tables safe)
      await RestaurantOrder.deleteMany({ isPaid: true });

      // Clean only paid cafe orders
      await CafeOrder.deleteMany({ isPaid: true });

      // Clean period expenses, notifications & settled invoices
      await Expense.deleteMany({});
      await Notification.deleteMany({});
      await Invoice.deleteMany({ paymentStatus: 'paid' });
    }

    // 2. In-memory store cleanup
    // Retain currently in-house (checkedIn) and future (confirmed) room bookings
    store.data.bookings = (store.data.bookings || []).filter(
      b => b.status === 'checkedIn' || b.status === 'confirmed'
    );

    // Retain upcoming banquet events: ONLY confirmed bookings for today or future dates
    // All completed, cancelled, or past events are deleted!
    store.data.banquetBookings = (store.data.banquetBookings || []).filter(
      b => b.status === 'confirmed' && b.eventDate && b.eventDate >= todayStr
    );

    // Retain active unpaid restaurant orders
    store.data.restaurantOrders = (store.data.restaurantOrders || []).filter(
      o => o.isPaid !== true
    );

    // Retain active unpaid cafe orders
    store.data.cafeOrders = (store.data.cafeOrders || []).filter(
      o => o.isPaid !== true
    );

    // Reset period expenses & notifications
    store.data.expenses = [];
    store.data.notifications = [];

    // 3. Smart Room Status Maintenance:
    // Keep rooms occupied if in-house guests are currently staying, keep reserved if confirmed for today
    const activeCheckedInBookings = (store.data.bookings || []).filter(b => b.status === 'checkedIn');
    const activeOccupiedRoomIds = new Set(
      activeCheckedInBookings.map(b => String(b.roomId || b.roomNumber).toLowerCase())
    );

    const upcomingTodayBookings = (store.data.bookings || []).filter(
      b => b.status === 'confirmed' && b.checkInDate && b.checkInDate <= todayStr
    );
    const reservedRoomIds = new Set(
      upcomingTodayBookings.map(b => String(b.roomId || b.roomNumber).toLowerCase())
    );

    for (const r of store.data.rooms) {
      const roomIdStr = String(r.id).toLowerCase();
      const roomNumStr = String(r.number).toLowerCase();
      const isOccupied = activeOccupiedRoomIds.has(roomIdStr) || activeOccupiedRoomIds.has(roomNumStr);
      const isReserved = reservedRoomIds.has(roomIdStr) || reservedRoomIds.has(roomNumStr);

      if (isOccupied) {
        r.status = 'occupied';
        const activeB = activeCheckedInBookings.find(
          b => String(b.roomId || b.roomNumber).toLowerCase() === roomIdStr || String(b.roomId || b.roomNumber).toLowerCase() === roomNumStr
        );
        if (activeB) {
          r.currentGuestName = activeB.guestName;
          r.currentBookingId = activeB.id;
          r.checkInDate = activeB.checkInDate;
          r.checkOutDate = activeB.checkOutDate;
        }
        SupabaseMasterService.saveRoom(r).catch(() => {});
      } else if (isReserved) {
        r.status = 'reserved';
        const upcomingB = upcomingTodayBookings.find(
          b => String(b.roomId || b.roomNumber).toLowerCase() === roomIdStr || String(b.roomId || b.roomNumber).toLowerCase() === roomNumStr
        );
        if (upcomingB) {
          r.currentGuestName = upcomingB.guestName;
          r.currentBookingId = upcomingB.id;
        }
        SupabaseMasterService.saveRoom(r).catch(() => {});
      } else {
        // Room has no active guest, reset to available
        r.status = 'available';
        delete r.currentGuestName;
        delete r.currentGuestId;
        delete r.currentBookingId;
        delete r.checkInDate;
        delete r.checkOutDate;
        SupabaseMasterService.saveRoom(r).catch(() => {});
      }
    }

    // 4. Smart Restaurant Table Status:
    // Do NOT reset tables that have live running orders
    const activeUnpaidOrders = (store.data.restaurantOrders || []).filter(o => o.isPaid !== true);
    const activeTableTargets = new Set(
      activeUnpaidOrders.map(o => String(o.target || o.tableId || '').toLowerCase())
    );

    for (const t of (store.data.restaurantTables || [])) {
      const tableIdStr = String(t.id).toLowerCase();
      const tableNameStr = String(t.name || '').toLowerCase();
      const tableNumStr = String(t.tableNumber || '').toLowerCase();
      const isTableActive = activeTableTargets.has(tableIdStr) || activeTableTargets.has(tableNameStr) || activeTableTargets.has(tableNumStr);

      if (!isTableActive) {
        t.status = 'available';
        t.currentOrderId = null;
        t.currentBillAmount = 0;
        SupabaseMasterService.saveTable(t).catch(() => {});
      }
    }

    // 5. Advance 10-Day Cycle tracking in MongoDB
    if (mongoose.connection.readyState === 1) {
      currentCycle.cycleNumber += 1;
      currentCycle.startDate = new Date();
      currentCycle.cleanupScheduledAt = null;
      currentCycle.isCleanupActive = false;

      const activeCycle = await ReportCycle.findOneAndUpdate(
        {},
        {
          cycleNumber: currentCycle.cycleNumber,
          startDate: currentCycle.startDate,
          cleanupScheduledAt: null,
          isCleanupActive: false,
          lastCleanupAt: new Date(),
        },
        { upsert: true, new: true }
      );

      if (activeCycle) {
        await ReportCycle.deleteMany({ _id: { $ne: activeCycle._id } }).catch(() => {});
      }
    }

    console.log('✅ Smart cleanup complete: Past completed data archived. In-house guests, future bookings & upcoming banquet events are 100% PRESERVED.');
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
    const cafeOrders = store.getCafeOrders ? store.getCafeOrders() : [];
    const banquetBookings = store.getBanquetBookings ? store.getBanquetBookings() : [];
    const expenses = store.getExpenses();

    const roomRevenue = bookings.reduce((sum, b) => sum + (Number(b.paidAmount) || Number(b.advancePaid) || 0), 0);
    const restaurantRevenue = orders.filter(o => o.isPaid).reduce((sum, o) => sum + (Number(o.total) || 0), 0);
    const cafeRevenue = cafeOrders.filter(o => o.isPaid).reduce((sum, o) => sum + (Number(o.total) || 0), 0);
    const banquetRevenue = banquetBookings.reduce((sum, b) => sum + (Number(b.advancePaid) || 0) + (Number(b.paidAmount) || 0), 0);
    const totalRevenue = roomRevenue + restaurantRevenue + cafeRevenue + banquetRevenue;
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
          cafeRevenue,
          banquetRevenue,
          totalRevenue,
          totalExpenses,
          netProfit,
          totalBookingsCount: bookings.length,
          totalOrdersCount: orders.length,
          totalCafeOrdersCount: cafeOrders.length,
          totalBanquetBookingsCount: banquetBookings.length,
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

    const cafeOrders = (store.getCafeOrders ? store.getCafeOrders() : []).map(o => ({
      id: o.id,
      orderNumber: o.orderNumber || o.id,
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

    const banquetBookings = (store.getBanquetBookings ? store.getBanquetBookings() : []).map(b => ({
      id: b.id,
      bookingNumber: b.bookingNumber || b.id,
      customerName: b.customerName || 'Client',
      customerPhone: b.customerPhone || '',
      hallName: b.hallName || '',
      eventType: b.eventType || 'Event',
      eventDate: b.eventDate || '',
      slot: b.slot || 'Evening',
      expectedGuests: Number(b.expectedGuests) || 0,
      grandTotal: Number(b.grandTotal) || 0,
      advancePaid: Number(b.advancePaid) || 0,
      balanceDue: Number(b.balanceDue) || 0,
      status: b.status || 'confirmed',
    }));

    const roomRevenue = bookings.reduce((sum, b) => sum + b.paidAmount, 0);
    const restaurantRevenue = orders.filter(o => o.isPaid).reduce((sum, o) => sum + o.total, 0);
    const cafeRevenue = cafeOrders.filter(o => o.isPaid).reduce((sum, o) => sum + o.total, 0);
    const banquetRevenue = banquetBookings.reduce((sum, b) => sum + (Number(b.advancePaid) || 0) + (Number(b.paidAmount) || 0), 0);
    const totalRevenue = roomRevenue + restaurantRevenue + cafeRevenue + banquetRevenue;
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
          cafeRevenue,
          banquetRevenue,
          totalRevenue,
          totalExpenses,
          netProfit,
          bookingsCount: bookings.length,
          ordersCount: orders.length,
          cafeOrdersCount: cafeOrders.length,
          banquetBookingsCount: banquetBookings.length,
          expensesCount: expenses.length,
        },
        bookings,
        orders,
        cafeOrders,
        banquetBookings,
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
      await ReportCycle.findOneAndUpdate(
        {},
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
      await ReportCycle.findOneAndUpdate(
        {},
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
