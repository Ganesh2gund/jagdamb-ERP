import { seedData } from './seedData.js';
import {
  Room,
  Booking,
  Guest,
  MenuItem,
  RestaurantCategory,
  RestaurantTable,
  RestaurantOrder,
  Expense,
  Inventory,
  Notification,
  Settings,
  Invoice,
} from '../models/index.js';
import mongoose from 'mongoose';
import { SupabaseMasterService } from '../services/supabaseService.js';

class MongoBackedStore {
  constructor() {
    this.data = JSON.parse(JSON.stringify(seedData));
    this.isMongoConnected = false;
  }

  // Check if MongoDB is currently ready
  isConnected() {
    return mongoose.connection.readyState === 1;
  }

  // Initialize store: load master data from Supabase Cloud & transactional data from MongoDB
  async init() {
    // 1. Load Permanent Master Data from Supabase Cloud
    try {
      console.log('🔄 Loading Master Data from Supabase Cloud...');
      const [supaRooms, supaMenu, supaCats, supaTables] = await Promise.all([
        SupabaseMasterService.getRooms(),
        SupabaseMasterService.getMenu(),
        SupabaseMasterService.getCategories(),
        SupabaseMasterService.getTables(),
      ]);

      if (supaRooms && supaRooms.length > 0) {
        this.data.rooms = supaRooms;
        console.log(`✅ Loaded ${supaRooms.length} rooms from Supabase.`);
      }
      if (supaMenu && supaMenu.length > 0) {
        this.data.restaurantMenu = supaMenu;
        console.log(`✅ Loaded ${supaMenu.length} menu items from Supabase.`);
      }
      if (supaCats && supaCats.length > 0) {
        this.data.restaurantCategories = supaCats;
        console.log(`✅ Loaded ${supaCats.length} categories from Supabase.`);
      }
      if (supaTables && supaTables.length > 0) {
        this.data.restaurantTables = supaTables;
        console.log(`✅ Loaded ${supaTables.length} tables from Supabase.`);
      }
    } catch (err) {
      console.warn('⚠️ Supabase Master Data load warning:', err.message);
    }

    if (!this.isConnected()) {
      console.log('ℹ️ MongoDB not connected; starting with cached data.');
      return;
    }

    try {
      console.log('🔄 Syncing transactional data with MongoDB Atlas...');

      // Fallback for rooms if Supabase was empty
      if (!this.data.rooms || this.data.rooms.length === 0) {
        const dbRooms = await Room.find().lean();
        this.data.rooms = (dbRooms || []).map(r => {
          const { _id, __v, ...rest } = r;
          return rest;
        });
      }

      // 2. Bookings (Transactional - MongoDB)
      const dbBookings = await Booking.find().sort({ createdAt: -1 }).lean();
      if (dbBookings && dbBookings.length > 0) {
        this.data.bookings = dbBookings.map(b => {
          const { _id, __v, ...rest } = b;
          return rest;
        });
      }

      // 3. Guests
      const dbGuests = await Guest.find().lean();
      if (dbGuests && dbGuests.length > 0) {
        this.data.guests = dbGuests.map(g => {
          const { _id, __v, ...rest } = g;
          return rest;
        });
      }

      // Fallback for menu if Supabase was empty
      if (!this.data.restaurantMenu || this.data.restaurantMenu.length === 0) {
        const dbMenu = await MenuItem.find().lean();
        if (dbMenu && dbMenu.length > 0) {
          this.data.restaurantMenu = dbMenu.map(m => {
            const { _id, __v, ...rest } = m;
            return rest;
          });
        }
      }

      // Fallback for categories if Supabase was empty
      if (!this.data.restaurantCategories || this.data.restaurantCategories.length === 0) {
        const dbCategories = await RestaurantCategory.find().lean();
        if (dbCategories && dbCategories.length > 0) {
          this.data.restaurantCategories = dbCategories.map(c => c.name);
        }
      }

      // Fallback for tables if Supabase was empty
      if (!this.data.restaurantTables || this.data.restaurantTables.length === 0) {
        const dbTables = await RestaurantTable.find().lean();
        if (dbTables && dbTables.length > 0) {
          this.data.restaurantTables = dbTables.map(t => {
            const { _id, __v, ...rest } = t;
            return rest;
          });
        }
      }

      // 7. Restaurant Orders (Transactional - MongoDB)
      const dbOrders = await RestaurantOrder.find().sort({ createdAt: -1 }).lean();
      if (dbOrders && dbOrders.length > 0) {
        this.data.restaurantOrders = dbOrders.map(o => {
          const { _id, __v, ...rest } = o;
          return rest;
        });
      }

      // 8. Expenses (Transactional - MongoDB)
      const dbExpenses = await Expense.find().sort({ date: -1 }).lean();
      if (dbExpenses && dbExpenses.length > 0) {
        this.data.expenses = dbExpenses.map(e => {
          const { _id, __v, ...rest } = e;
          return rest;
        });
      }

      // 9. Inventory
      const dbInventory = await Inventory.find().lean();
      if (dbInventory && dbInventory.length > 0) {
        this.data.inventoryItems = dbInventory.map(i => {
          const { _id, __v, ...rest } = i;
          return rest;
        });
      }

      // 10. Notifications
      const dbNotifications = await Notification.find().sort({ time: -1 }).lean();
      if (dbNotifications && dbNotifications.length > 0) {
        this.data.notifications = dbNotifications.map(n => {
          const { _id, __v, ...rest } = n;
          return rest;
        });
      }

      this.isMongoConnected = true;
      console.log('✅ MongoDB Atlas synchronized successfully!');
    } catch (err) {
      console.error('❌ Error during MongoDB cache initialization:', err.message);
    }
  }

  // Auth
  validateAdmin(email, password) {
    return email === 'tejas@gmail.com' && password === 'tejas4010';
  }

  // ── Rooms ───────────────────────────────────────
  getRooms() {
    return this.data.rooms;
  }

  getRoomById(id) {
    if (!id) return null;
    const strId = String(id).trim().toLowerCase();
    return this.data.rooms.find(r =>
      String(r.id).toLowerCase() === strId ||
      String(r.number).toLowerCase() === strId ||
      'r' + String(r.number).toLowerCase() === strId
    );
  }

  updateRoomStatus(id, status, maintenanceNote) {
    const room = this.getRoomById(id);
    if (!room) return null;
    room.status = status;
    if (maintenanceNote !== undefined) room.maintenanceNote = maintenanceNote;
    if (status === 'available' || status === 'cleaning') {
      delete room.currentGuestName;
      delete room.currentGuestId;
      delete room.currentBookingId;
      delete room.checkInDate;
      delete room.checkOutDate;
    }

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveRoom(room).catch(e => console.error('Error updating room in Supabase:', e.message));

    if (this.isConnected()) {
      Room.findOneAndUpdate(
        { $or: [{ id: room.id }, { number: room.number }] },
        {
          status: room.status,
          maintenanceNote: room.maintenanceNote,
          currentGuestName: room.currentGuestName || null,
          currentGuestId: room.currentGuestId || null,
          currentBookingId: room.currentBookingId || null,
          checkInDate: room.checkInDate || null,
          checkOutDate: room.checkOutDate || null,
        }
      ).catch(e => console.error('Error updating room in Mongo:', e.message));
    }

    return room;
  }

  checkInRoom(roomId, guestId, guestName, bookingId, checkInDate, checkOutDate) {
    const room = this.getRoomById(roomId);
    if (!room) return null;
    room.status = 'occupied';
    room.currentGuestId = guestId;
    room.currentGuestName = guestName;
    room.currentBookingId = bookingId;
    room.checkInDate = checkInDate;
    room.checkOutDate = checkOutDate;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveRoom(room).catch(e => console.error('Error checking in room in Supabase:', e.message));

    if (this.isConnected()) {
      Room.findOneAndUpdate(
        { $or: [{ id: room.id }, { number: room.number }] },
        {
          status: 'occupied',
          currentGuestId: guestId,
          currentGuestName: guestName,
          currentBookingId: bookingId,
          checkInDate,
          checkOutDate,
        }
      ).catch(e => console.error('Error in checkInRoom Mongo:', e.message));
    }

    return room;
  }

  checkOutRoom(roomId) {
    return this.updateRoomStatus(roomId, 'available');
  }

  createRoom(payload) {
    const newRoom = {
      id: 'r' + payload.number,
      ...payload,
    };
    this.data.rooms.push(newRoom);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveRoom(newRoom).catch(e => console.error('Error creating room in Supabase:', e.message));

    if (this.isConnected()) {
      Room.create(newRoom).catch(e => console.error('Error creating room in Mongo:', e.message));
    }

    return newRoom;
  }

  updateRoom(id, updates) {
    const room = this.getRoomById(id);
    if (!room) return null;
    const allowed = ['number', 'floor', 'type', 'pricePerNight', 'amenities', 'maxGuests', 'imageUrl', 'maintenanceNote'];
    for (const key of allowed) {
      if (updates[key] !== undefined) room[key] = updates[key];
    }

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveRoom(room).catch(e => console.error('Error updating room in Supabase:', e.message));

    if (this.isConnected()) {
      Room.findOneAndUpdate(
        { $or: [{ id: room.id }, { number: room.number }] },
        updates
      ).catch(e => console.error('Error updating room in Mongo:', e.message));
    }

    return room;
  }

  deleteRoom(id) {
    const idx = this.data.rooms.findIndex(r => r.id === id || r.number === id);
    if (idx !== -1) {
      const removed = this.data.rooms.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteRoom(removed.id).catch(e => console.error('Error deleting room from Supabase:', e.message));

      if (this.isConnected()) {
        Room.deleteOne({ $or: [{ id: removed.id }, { number: removed.number }] })
          .catch(e => console.error('Error deleting room from Mongo:', e.message));
      }
    }
  }

  // ── Bookings ────────────────────────────────────
  getBookings() {
    return this.data.bookings;
  }

  getBookingById(id) {
    return this.data.bookings.find(b => b.id === id || b.bookingNumber === id);
  }

  createBooking(bookingPayload) {
    const newBooking = {
      id: 'b' + (this.data.bookings.length + 1),
      bookingNumber: `BK-2026-${String(this.data.bookings.length + 1).padStart(3, '0')}`,
      createdAt: new Date().toISOString(),
      status: 'confirmed',
      paymentStatus: 'pending',
      ...bookingPayload,
    };
    this.data.bookings.unshift(newBooking);

    const room = this.getRoomById(newBooking.roomId);
    if (room && room.status === 'available') {
      room.status = 'reserved';
      room.currentGuestName = newBooking.guestName;
      if (this.isConnected()) {
        Room.findOneAndUpdate(
          { $or: [{ id: room.id }, { number: room.number }] },
          { status: 'reserved', currentGuestName: newBooking.guestName }
        ).catch(e => console.error('Error updating room status in Mongo:', e.message));
      }
    }

    // Auto-create or link guest record
    if (newBooking.guestName) {
      let guest = this.data.guests.find(g => g.name.toLowerCase() === newBooking.guestName.toLowerCase());
      if (!guest && newBooking.guestPhone) {
        this.createGuest({
          name: newBooking.guestName,
          phone: newBooking.guestPhone,
          email: newBooking.guestEmail || '',
        });
      }
    }

    if (this.isConnected()) {
      Booking.create(newBooking).catch(e => console.error('Error creating booking in Mongo:', e.message));
    }

    return newBooking;
  }

  updateBookingStatus(id, status) {
    const booking = this.getBookingById(id);
    if (!booking) return null;
    booking.status = status;
    if (status === 'checkedOut') {
      booking.paymentStatus = 'paid';
      booking.paidAmount = booking.totalAmount;
      if (booking.roomId || booking.roomNumber) {
        this.checkOutRoom(booking.roomId || booking.roomNumber);
      }

      // Persist billing/invoice record to MongoDB
      this.recordBookingInvoice(booking);
    }

    if (this.isConnected()) {
      Booking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        { status: booking.status, paymentStatus: booking.paymentStatus, paidAmount: booking.paidAmount }
      ).catch(e => console.error('Error updating booking in Mongo:', e.message));
    }

    return booking;
  }

  updateBookingPayment(id, paymentStatus, paidAmount) {
    const booking = this.getBookingById(id);
    if (!booking) return null;
    if (paymentStatus) booking.paymentStatus = paymentStatus;
    if (paidAmount !== undefined) booking.paidAmount = Number(paidAmount);

    if (this.isConnected()) {
      Booking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        { paymentStatus: booking.paymentStatus, paidAmount: booking.paidAmount }
      ).catch(e => console.error('Error updating booking payment in Mongo:', e.message));
    }

    return booking;
  }

  updateBooking(id, updates) {
    const booking = this.getBookingById(id);
    if (!booking) return null;

    if (updates.roomId && updates.roomId !== booking.roomId) {
      const oldRoom = this.getRoomById(booking.roomId);
      if (oldRoom && oldRoom.status === 'reserved') {
        oldRoom.status = 'available';
        delete oldRoom.currentGuestName;
        delete oldRoom.currentBookingId;
        if (this.isConnected()) {
          Room.findOneAndUpdate({ id: oldRoom.id }, { status: 'available', currentGuestName: null, currentBookingId: null }).catch(() => {});
        }
      }
      const newRoom = this.getRoomById(updates.roomId);
      if (newRoom && newRoom.status === 'available') {
        newRoom.status = 'reserved';
        newRoom.currentGuestName = updates.guestName || booking.guestName;
        newRoom.currentBookingId = booking.id;
        if (this.isConnected()) {
          Room.findOneAndUpdate({ id: newRoom.id }, { status: 'reserved', currentGuestName: newRoom.currentGuestName, currentBookingId: booking.id }).catch(() => {});
        }
      }
    }

    Object.assign(booking, updates);

    if (this.isConnected()) {
      Booking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        updates
      ).catch(e => console.error('Error updating booking in Mongo:', e.message));
    }

    return booking;
  }

  cancelBooking(id, reason) {
    const booking = this.getBookingById(id);
    if (!booking) return null;

    booking.status = 'cancelled';
    booking.cancellationReason = reason || 'Cancelled by admin';

    const room = this.getRoomById(booking.roomId);
    if (room && (room.status === 'reserved' || room.status === 'occupied')) {
      room.status = 'available';
      delete room.currentGuestName;
      delete room.currentGuestId;
      delete room.currentBookingId;
      delete room.checkInDate;
      delete room.checkOutDate;
      if (this.isConnected()) {
        Room.findOneAndUpdate({ id: room.id }, {
          status: 'available',
          currentGuestName: null,
          currentGuestId: null,
          currentBookingId: null,
          checkInDate: null,
          checkOutDate: null,
        }).catch(() => {});
      }
    }

    if (this.isConnected()) {
      Booking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        { status: 'cancelled', cancellationReason: booking.cancellationReason }
      ).catch(e => console.error('Error cancelling booking in Mongo:', e.message));
    }

    return booking;
  }

  // ── Guests ──────────────────────────────────────
  getGuests() {
    return this.data.guests;
  }

  getGuestById(id) {
    return this.data.guests.find(g => g.id === id);
  }

  createGuest(payload) {
    const newGuest = {
      id: 'g' + (this.data.guests.length + 1),
      totalStays: 1,
      totalSpent: 0,
      isVip: false,
      ...payload,
    };
    this.data.guests.push(newGuest);

    if (this.isConnected()) {
      Guest.create(newGuest).catch(e => console.error('Error creating guest in Mongo:', e.message));
    }

    return newGuest;
  }

  // ── Restaurant: Menu & Categories ───────────────
  getMenu() {
    if (!this.data.restaurantMenu) this.data.restaurantMenu = [];
    return this.data.restaurantMenu;
  }

  addMenuItem(payload) {
    if (!this.data.restaurantMenu) this.data.restaurantMenu = [];
    const newItem = {
      id: 'm_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      name: payload.name,
      category: payload.category || 'Main Course',
      price: Number(payload.price) || 0,
      isVeg: payload.isVeg === true,
      description: payload.description || '',
      isAvailable: true,
    };
    this.data.restaurantMenu.push(newItem);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveMenuItem(newItem).catch(e => console.error('Error saving menu item in Supabase:', e.message));

    if (this.isConnected()) {
      MenuItem.create(newItem).catch(e => console.error('Error creating menu item in Mongo:', e.message));
    }

    return newItem;
  }

  updateMenuItem(id, updates) {
    if (!this.data.restaurantMenu) return null;
    const strId = String(id).trim();
    const item = this.data.restaurantMenu.find(m => String(m.id) === strId);
    if (!item) return null;
    if (updates.name !== undefined) item.name = updates.name;
    if (updates.category !== undefined) item.category = updates.category;
    if (updates.price !== undefined) item.price = Number(updates.price) || 0;
    if (updates.isVeg !== undefined) item.isVeg = updates.isVeg === true;
    if (updates.description !== undefined) item.description = updates.description;
    if (updates.isAvailable !== undefined) item.isAvailable = updates.isAvailable;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveMenuItem(item).catch(e => console.error('Error updating menu item in Supabase:', e.message));

    if (this.isConnected()) {
      MenuItem.findOneAndUpdate({ id: item.id }, updates).catch(e => console.error('Error updating menu item in Mongo:', e.message));
    }

    return item;
  }

  deleteMenuItem(id) {
    if (!this.data.restaurantMenu) return false;
    const strId = String(id).trim();
    const idx = this.data.restaurantMenu.findIndex(m => String(m.id) === strId);
    if (idx !== -1) {
      const removed = this.data.restaurantMenu.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteMenuItem(removed.id).catch(e => console.error('Error deleting menu item from Supabase:', e.message));

      if (this.isConnected()) {
        MenuItem.deleteOne({ id: removed.id }).catch(e => console.error('Error deleting menu item in Mongo:', e.message));
      }
      return true;
    }
    return false;
  }

  getCategories() {
    if (!this.data.restaurantCategories) this.data.restaurantCategories = [];
    return this.data.restaurantCategories;
  }

  addCategory(name) {
    if (!this.data.restaurantCategories) this.data.restaurantCategories = [];
    const clean = String(name).trim();
    if (!this.data.restaurantCategories.includes(clean)) {
      this.data.restaurantCategories.push(clean);
      // Save to Supabase Cloud (Master)
      SupabaseMasterService.saveCategory(clean).catch(e => console.error('Error saving category in Supabase:', e.message));

      if (this.isConnected()) {
        RestaurantCategory.create({ name: clean }).catch(e => console.error('Error creating category in Mongo:', e.message));
      }
    }
    return clean;
  }

  deleteCategory(name) {
    if (!this.data.restaurantCategories) return false;
    const clean = String(name).trim();
    const idx = this.data.restaurantCategories.indexOf(clean);
    if (idx !== -1) {
      this.data.restaurantCategories.splice(idx, 1);
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteCategory(clean).catch(e => console.error('Error deleting category from Supabase:', e.message));

      if (this.isConnected()) {
        RestaurantCategory.deleteOne({ name: clean }).catch(e => console.error('Error deleting category in Mongo:', e.message));
      }
      return true;
    }
    return false;
  }

  // ── Restaurant: Tables ──────────────────────────
  getTables() {
    if (!this.data.restaurantTables) this.data.restaurantTables = [];
    return this.data.restaurantTables;
  }

  getTableById(id) {
    return (this.data.restaurantTables || []).find(t => String(t.id) === String(id) || String(t.number) === String(id));
  }

  createTable(payload) {
    if (!this.data.restaurantTables) this.data.restaurantTables = [];
    const newTable = {
      id: 'tbl_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      number: String(payload.number),
      capacity: Number(payload.capacity) || 4,
      status: 'available',
      currentBillAmount: 0,
    };
    this.data.restaurantTables.push(newTable);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveTable(newTable).catch(e => console.error('Error saving table in Supabase:', e.message));

    if (this.isConnected()) {
      RestaurantTable.create(newTable).catch(e => console.error('Error creating table in Mongo:', e.message));
    }

    return newTable;
  }

  updateTable(id, updates) {
    const table = this.getTableById(id);
    if (!table) return null;
    if (updates.number !== undefined) table.number = String(updates.number);
    if (updates.capacity !== undefined) table.capacity = Number(updates.capacity) || 4;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveTable(table).catch(e => console.error('Error updating table in Supabase:', e.message));

    if (this.isConnected()) {
      RestaurantTable.findOneAndUpdate({ id: table.id }, updates).catch(e => console.error('Error updating table in Mongo:', e.message));
    }

    return table;
  }

  deleteTable(id) {
    if (!this.data.restaurantTables) return false;
    const strId = String(id).trim();
    const idx = this.data.restaurantTables.findIndex(t => String(t.id) === strId || String(t.number) === strId);
    if (idx !== -1) {
      const removed = this.data.restaurantTables.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteTable(removed.id).catch(e => console.error('Error deleting table from Supabase:', e.message));

      if (this.isConnected()) {
        RestaurantTable.deleteOne({ id: removed.id }).catch(e => console.error('Error deleting table in Mongo:', e.message));
      }
      return true;
    }
    return false;
  }

  updateTableStatus(id, status, currentOrderId = null, currentBillAmount = 0) {
    const table = this.getTableById(id);
    if (!table) return null;
    table.status = status;
    table.currentOrderId = currentOrderId;
    table.currentBillAmount = currentBillAmount;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveTable(table).catch(e => console.error('Error updating table status in Supabase:', e.message));

    if (this.isConnected()) {
      RestaurantTable.findOneAndUpdate({ id: table.id }, { status, currentOrderId, currentBillAmount })
        .catch(e => console.error('Error updating table status in Mongo:', e.message));
    }

    return table;
  }

  // ── Restaurant: Orders & Settlement ─────────────
  getOrders() {
    if (!this.data.restaurantOrders) this.data.restaurantOrders = [];
    return this.data.restaurantOrders;
  }

  createOrder(payload) {
    if (!this.data.restaurantOrders) this.data.restaurantOrders = [];
    const items = (payload.items || []).map(it => ({
      name: it.name || '',
      price: Number(it.price) || 0,
      quantity: Number(it.quantity) || 1,
    }));
    const subtotal = payload.subtotal !== undefined ? payload.subtotal : items.reduce((sum, it) => sum + (it.price * it.quantity), 0);
    const tax = payload.tax !== undefined ? payload.tax : 0;
    const total = payload.total !== undefined ? payload.total : subtotal + tax;

    const newOrder = {
      id: 'ord_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      orderNumber: `ORD-${String(this.data.restaurantOrders.length + 1).padStart(3, '0')}`,
      type: payload.type || 'dineIn',
      target: payload.target || 'Counter',
      guestName: payload.guestName || 'Walk-in Guest',
      items,
      subtotal,
      tax,
      total,
      isPaid: payload.isPaid !== undefined ? payload.isPaid : true,
      paymentMethod: payload.paymentMethod || 'Cash',
      status: 'received',
      createdAt: new Date().toISOString(),
    };
    this.data.restaurantOrders.unshift(newOrder);

    // Update linked table if dineIn
    if (newOrder.target && newOrder.target.toLowerCase().includes('table')) {
      const table = this.getTableById(newOrder.target.replace(/table\s*/i, '').trim());
      if (table) {
        this.updateTableStatus(table.id, 'occupied', newOrder.id, newOrder.total);
      }
    }

    if (this.isConnected()) {
      RestaurantOrder.create(newOrder).catch(e => console.error('Error creating order in Mongo:', e.message));
    }

    return newOrder;
  }

  updateOrderStatus(id, status) {
    if (!this.data.restaurantOrders) return null;
    const strId = String(id).trim();
    const order = this.data.restaurantOrders.find(o => String(o.id) === strId || String(o.orderNumber) === strId);
    if (!order) return null;
    order.status = status;

    if (this.isConnected()) {
      RestaurantOrder.findOneAndUpdate({ id: order.id }, { status }).catch(e => console.error('Error updating order in Mongo:', e.message));
    }

    return order;
  }

  settleOrder(id, paymentMethod = 'Cash', tax = 0, grandTotal) {
    if (!this.data.restaurantOrders) return null;
    const strId = String(id).trim();
    const order = this.data.restaurantOrders.find(o => String(o.id) === strId || String(o.orderNumber) === strId);
    if (!order) return null;

    order.isPaid = true;
    order.paymentMethod = paymentMethod || 'Cash';
    if (tax !== undefined) order.tax = tax;
    if (grandTotal !== undefined) order.total = grandTotal;
    order.status = 'served';

    // Clear linked table
    if (order.target) {
      const table = (this.data.restaurantTables || []).find(t =>
        t.number.toLowerCase() === order.target.toLowerCase() ||
        t.id.toLowerCase() === order.target.toLowerCase() ||
        ('table ' + t.number.toLowerCase()) === order.target.toLowerCase()
      );
      if (table) {
        this.updateTableStatus(table.id, 'available', null, 0);
      }
    }

    // Persist billing/invoice record to MongoDB
    this.recordRestaurantInvoice(order);

    if (this.isConnected()) {
      RestaurantOrder.findOneAndUpdate(
        { id: order.id },
        { isPaid: true, paymentMethod: order.paymentMethod, tax: order.tax, total: order.total, status: 'served' }
      ).catch(e => console.error('Error settling order in Mongo:', e.message));
    }

    return order;
  }

  // ── Invoices / Billing Records (Persistent in MongoDB) ───────────
  recordBookingInvoice(booking) {
    if (!this.isConnected()) return;
    try {
      const invoiceData = {
        invoiceNumber: `INV-${booking.bookingNumber || booking.id}`,
        type: 'room',
        bookingId: booking.id,
        customerName: booking.guestName,
        customerPhone: booking.guestPhone || '',
        roomInformation: {
          roomNumber: booking.roomNumber || booking.roomId,
          checkInDate: booking.checkInDate,
          checkOutDate: booking.checkOutDate,
          nights: booking.totalNights || 1,
        },
        subtotal: booking.totalAmount || 0,
        tax: 0,
        discount: 0,
        total: booking.totalAmount || 0,
        paidAmount: booking.paidAmount || booking.totalAmount || 0,
        balanceDue: 0,
        paymentMethod: booking.paymentMethod || 'Cash',
        paymentStatus: 'paid',
        dateTime: new Date().toISOString(),
      };
      Invoice.findOneAndUpdate(
        { invoiceNumber: invoiceData.invoiceNumber },
        invoiceData,
        { upsert: true, new: true }
      ).catch(e => console.error('Error recording booking invoice in Mongo:', e.message));
    } catch (e) {
      console.error('Invoice recording error:', e.message);
    }
  }

  recordRestaurantInvoice(order) {
    if (!this.isConnected()) return;
    try {
      const invoiceData = {
        invoiceNumber: `INV-${order.orderNumber || order.id}`,
        type: 'restaurant',
        orderId: order.id,
        customerName: order.guestName || 'Walk-in Guest',
        restaurantItems: order.items || [],
        subtotal: order.subtotal || order.total,
        tax: order.tax || 0,
        discount: 0,
        total: order.total,
        paidAmount: order.total,
        balanceDue: 0,
        paymentMethod: order.paymentMethod || 'Cash',
        paymentStatus: 'paid',
        dateTime: new Date().toISOString(),
      };
      Invoice.findOneAndUpdate(
        { invoiceNumber: invoiceData.invoiceNumber },
        invoiceData,
        { upsert: true, new: true }
      ).catch(e => console.error('Error recording restaurant invoice in Mongo:', e.message));
    } catch (e) {
      console.error('Invoice recording error:', e.message);
    }
  }

  // ── Expenses ────────────────────────────────────
  getExpenses() {
    return this.data.expenses;
  }

  addExpense(payload) {
    const newExpense = {
      id: payload.id || ('exp' + (this.data.expenses.length + 1)),
      date: payload.date || new Date().toISOString().split('T')[0],
      ...payload,
    };
    this.data.expenses.unshift(newExpense);

    if (this.isConnected()) {
      Expense.create(newExpense).catch(e => console.error('Error creating expense in Mongo:', e.message));
    }

    return newExpense;
  }

  updateExpense(id, updates) {
    if (!this.data.expenses) this.data.expenses = [];
    const strId = String(id).trim().toLowerCase();
    const exp = this.data.expenses.find(e => String(e.id).trim().toLowerCase() === strId);
    if (!exp) {
      const newExp = {
        id: String(id),
        date: updates.date || new Date().toISOString().split('T')[0],
        category: updates.category || 'Other',
        amount: Number(updates.amount) || 0,
        description: updates.description || '',
        paymentMethod: updates.paymentMethod || 'Cash',
        notes: updates.notes || null,
      };
      this.data.expenses.unshift(newExp);
      if (this.isConnected()) {
        Expense.create(newExp).catch(e => console.error('Error creating expense in Mongo:', e.message));
      }
      return newExp;
    }

    if (updates.category !== undefined) exp.category = updates.category;
    if (updates.amount !== undefined) exp.amount = Number(updates.amount) || exp.amount;
    if (updates.description !== undefined) exp.description = updates.description;
    if (updates.paymentMethod !== undefined) exp.paymentMethod = updates.paymentMethod;
    if (updates.notes !== undefined) exp.notes = updates.notes;
    if (updates.date !== undefined) exp.date = updates.date;

    if (this.isConnected()) {
      Expense.findOneAndUpdate({ id: exp.id }, updates).catch(e => console.error('Error updating expense in Mongo:', e.message));
    }

    return exp;
  }

  deleteExpense(id) {
    if (!this.data.expenses) return true;
    const strId = String(id).trim().toLowerCase();
    const idx = this.data.expenses.findIndex(e => String(e.id).trim().toLowerCase() === strId);
    if (idx !== -1) {
      const removed = this.data.expenses.splice(idx, 1)[0];
      if (this.isConnected()) {
        Expense.deleteOne({ id: removed.id }).catch(e => console.error('Error deleting expense in Mongo:', e.message));
      }
    }
    return true;
  }

  // ── Inventory ───────────────────────────────────
  getInventory() {
    return this.data.inventoryItems;
  }

  updateInventoryStock(id, newStock) {
    const item = this.data.inventoryItems.find(i => i.id === id);
    if (!item) return null;
    item.currentStock = newStock;
    item.isLowStock = item.currentStock <= item.minStock;

    if (this.isConnected()) {
      Inventory.findOneAndUpdate({ id }, { currentStock: newStock, isLowStock: item.isLowStock })
        .catch(e => console.error('Error updating inventory in Mongo:', e.message));
    }

    return item;
  }

  // ── Notifications ───────────────────────────────
  getNotifications() {
    return this.data.notifications;
  }

  markNotificationRead(id) {
    const notif = this.data.notifications.find(n => n.id === id);
    if (!notif) return null;
    notif.isRead = true;

    if (this.isConnected()) {
      Notification.findOneAndUpdate({ id }, { isRead: true })
        .catch(e => console.error('Error updating notification in Mongo:', e.message));
    }

    return notif;
  }

  // ── Dashboard Stats ─────────────────────────────
  getDashboardSummary() {
    const rooms = this.data.rooms;
    const totalRooms = rooms.length;
    const occupied = rooms.filter(r => r.status === 'occupied').length;
    const available = rooms.filter(r => r.status === 'available').length;
    const cleaning = rooms.filter(r => r.status === 'cleaning').length;
    const maintenance = rooms.filter(r => r.status === 'maintenance').length;
    const reserved = rooms.filter(r => r.status === 'reserved').length;
    const occupancyRate = totalRooms > 0 ? Math.round((occupied / totalRooms) * 100) : 0;

    // Room revenue from checked in/paid bookings
    const activeBookings = this.data.bookings.filter(b => b.status === 'checkedIn' || b.status === 'confirmed');
    const roomRevenue = activeBookings.reduce((sum, b) => sum + (Number(b.advancePaid) || 0) + (Number(b.paidAmount) || 0), 0);

    // Restaurant revenue from paid orders
    const paidRestaurantOrders = (this.data.restaurantOrders || []).filter(o => o.isPaid === true);
    const restaurantRevenue = paidRestaurantOrders.reduce((sum, o) => sum + (Number(o.total) || 0), 0);

    const revenueToday = roomRevenue + restaurantRevenue;
    const pendingCheckIns = this.data.bookings.filter(b => b.status === 'confirmed').length;

    return {
      totalRooms,
      occupied,
      available,
      cleaning,
      maintenance,
      reserved,
      occupancyRate,
      revenueToday,
      roomRevenue,
      restaurantRevenue,
      pendingCheckIns,
      activeGuests: occupied * 2,
    };
  }
}

export const store = new MongoBackedStore();
export default store;
