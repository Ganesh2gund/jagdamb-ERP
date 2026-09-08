import { seedData } from './seedData.js';
import {
  Booking,
  Guest,
  RestaurantOrder,
  Expense,
  Inventory,
  Notification,
  Invoice,
  CafeOrder,
  BanquetBooking,
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
      const [
        supaRooms,
        supaMenu,
        supaCats,
        supaTables,
        supaCafeMenu,
        supaCafeCats,
        supaBanquetHalls,
        supaBanquetPkgs,
      ] = await Promise.all([
        SupabaseMasterService.getRooms(),
        SupabaseMasterService.getMenu(),
        SupabaseMasterService.getCategories(),
        SupabaseMasterService.getTables(),
        SupabaseMasterService.getCafeMenu(),
        SupabaseMasterService.getCafeCategories(),
        SupabaseMasterService.getBanquetHalls(),
        SupabaseMasterService.getBanquetPackages(),
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
      if (supaCafeCats && supaCafeCats.length > 0) {
        this.data.cafeCategories = supaCafeCats;
        console.log(`✅ Loaded ${supaCafeCats.length} cafe categories from Supabase.`);
      } else {
        const defaultCafeCats = ['Hot Beverages', 'Cold Beverages', 'Snacks & Fast Food', 'Bakery & Desserts'];
        this.data.cafeCategories = defaultCafeCats;
        for (const c of defaultCafeCats) {
          SupabaseMasterService.saveCafeCategory(c).catch(() => {});
        }
      }
      if (supaCafeMenu && supaCafeMenu.length > 0) {
        this.data.cafeMenu = supaCafeMenu;
        console.log(`✅ Loaded ${supaCafeMenu.length} cafe menu items from Supabase.`);
      } else {
        const defaultCafeMenu = [
          { id: 'cm_1', name: 'Cappuccino', category: 'Hot Beverages', price: 90, isVeg: true, description: 'Rich espresso with steamed milk foam', isAvailable: true },
          { id: 'cm_2', name: 'Special Masala Chai', category: 'Hot Beverages', price: 30, isVeg: true, description: 'Cardamom and ginger infused tea', isAvailable: true },
          { id: 'cm_3', name: 'Cold Coffee with Ice Cream', category: 'Cold Beverages', price: 120, isVeg: true, description: 'Chilled blended coffee topped with vanilla scoop', isAvailable: true },
          { id: 'cm_4', name: 'Chocolate Thick Shake', category: 'Cold Beverages', price: 110, isVeg: true, description: 'Thick creamy Belgian chocolate shake', isAvailable: true },
          { id: 'cm_5', name: 'Fresh Lime Soda', category: 'Cold Beverages', price: 60, isVeg: true, description: 'Sweet and salted refreshing soda', isAvailable: true },
          { id: 'cm_6', name: 'Veg Grilled Cheese Sandwich', category: 'Snacks & Fast Food', price: 100, isVeg: true, description: 'Golden grilled sandwich with spiced vegetables', isAvailable: true },
          { id: 'cm_7', name: 'Crispy French Fries', category: 'Snacks & Fast Food', price: 80, isVeg: true, description: 'Salted golden potato fries with dip', isAvailable: true },
          { id: 'cm_8', name: 'Paneer Cheese Burger', category: 'Snacks & Fast Food', price: 130, isVeg: true, description: 'Crispy paneer patty with lettuce and cheese', isAvailable: true },
          { id: 'cm_9', name: 'Chocolate Brownie', category: 'Bakery & Desserts', price: 90, isVeg: true, description: 'Warm gooey chocolate brownie', isAvailable: true },
        ];
        this.data.cafeMenu = defaultCafeMenu;
        for (const item of defaultCafeMenu) {
          SupabaseMasterService.saveCafeMenuItem(item).catch(() => {});
        }
      }

      // Banquet Halls
      if (supaBanquetHalls !== null) {
        this.data.banquetHalls = supaBanquetHalls;
        console.log(`✅ Loaded ${supaBanquetHalls.length} banquet halls from Supabase.`);
      } else {
        this.data.banquetHalls = [];
      }

      // Banquet Packages
      if (supaBanquetPkgs && supaBanquetPkgs.length > 0) {
        this.data.banquetPackages = supaBanquetPkgs;
        console.log(`✅ Loaded ${supaBanquetPkgs.length} banquet packages from Supabase.`);
      } else {
        const defaultPkgs = [
          {
            id: 'pkg_silver',
            name: 'Silver Wedding / Party Package',
            pricePerPlate: 450,
            isVeg: true,
            description: 'Standard 3-course banquet meal with welcome drink',
            inclusions: ['Welcome Drink (Mocktail)', '2 Veg Starters', 'Paneer Sabji', 'Seasonal Veg', 'Dal Fry & Jeera Rice', 'Roti / Naan', 'Gulab Jamun & Ice Cream'],
          },
          {
            id: 'pkg_gold',
            name: 'Gold Grand Maharaja Package',
            pricePerPlate: 750,
            isVeg: true,
            description: 'Luxury lavish banquet spread with live counter & desserts',
            inclusions: ['2 Welcome Drinks', '4 Starters (Paneer Tikka, Crispy Veg)', 'Shahi Paneer', 'Veg Kofta', 'Dal Makhani', 'Dum Biryani with Raita', 'Assorted Breads', '2 Desserts (Rasmalai + Kulfi)', 'Salad & Chaat Counter'],
          },
          {
            id: 'pkg_corporate',
            name: 'Corporate High-Tea & Lunch Package',
            pricePerPlate: 350,
            isVeg: true,
            description: 'Business seminar package with morning tea/coffee & executive lunch',
            inclusions: ['Morning Tea/Coffee & Cookies', 'Executive Lunch Buffet', 'Evening High Tea & Snacks'],
          },
        ];
        this.data.banquetPackages = defaultPkgs;
        for (const p of defaultPkgs) {
          SupabaseMasterService.saveBanquetPackage(p).catch(() => {});
        }
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

      // 1. Bookings (Transactional - MongoDB)
      const dbBookings = await Booking.find().sort({ createdAt: -1 }).lean();
      if (dbBookings && dbBookings.length > 0) {
        this.data.bookings = dbBookings.map(b => {
          const { _id, __v, ...rest } = b;
          return rest;
        });
      }

      // 2. Guests (Transactional - MongoDB)
      const dbGuests = await Guest.find().lean();
      if (dbGuests && dbGuests.length > 0) {
        this.data.guests = dbGuests.map(g => {
          const { _id, __v, ...rest } = g;
          return rest;
        });
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

      // 11. Cafe Orders (Transactional - MongoDB)
      const dbCafeOrders = await CafeOrder.find().sort({ createdAt: -1 }).lean();
      if (dbCafeOrders && dbCafeOrders.length > 0) {
        this.data.cafeOrders = dbCafeOrders.map(o => {
          const { _id, __v, ...rest } = o;
          return rest;
        });
      } else {
        this.data.cafeOrders = [];
      }

      // 12. Banquet Bookings (Transactional - MongoDB)
      const dbBanquetBookings = await BanquetBooking.find().sort({ eventDate: -1 }).lean();
      if (dbBanquetBookings && dbBanquetBookings.length > 0) {
        this.data.banquetBookings = dbBanquetBookings.map(b => {
          const { _id, __v, ...rest } = b;
          return rest;
        });
      } else {
        this.data.banquetBookings = [];
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

    return room;
  }

  deleteRoom(id) {
    const idx = this.data.rooms.findIndex(r => r.id === id || r.number === id);
    if (idx !== -1) {
      const removed = this.data.rooms.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteRoom(removed.id).catch(e => console.error('Error deleting room from Supabase:', e.message));
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
      SupabaseMasterService.saveRoom(room).catch(() => {});
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
        SupabaseMasterService.saveRoom(oldRoom).catch(() => {});
      }
      const newRoom = this.getRoomById(updates.roomId);
      if (newRoom && newRoom.status === 'available') {
        newRoom.status = 'reserved';
        newRoom.currentGuestName = updates.guestName || booking.guestName;
        newRoom.currentBookingId = booking.id;
        SupabaseMasterService.saveRoom(newRoom).catch(() => {});
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
      SupabaseMasterService.saveRoom(room).catch(() => {});
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
    }
    return clean;
  }

  deleteCategory(name) {
    if (!this.data.restaurantCategories) return false;
    const clean = String(name).trim();
    const idx = this.data.restaurantCategories.indexOf(clean);
    if (idx !== -1) {
      this.data.restaurantCategories.splice(idx, 1);

      // Cascade remove dishes of this category in memory
      if (this.data.menuItems) {
        this.data.menuItems = this.data.menuItems.filter(
          m => String(m.category || '').trim().toLowerCase() !== clean.toLowerCase()
        );
      }

      // Delete from Supabase Cloud (Master) - cascade deletes category & menu items
      SupabaseMasterService.deleteCategory(clean).catch(e => console.error('Error deleting category from Supabase:', e.message));

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

    return newTable;
  }

  updateTable(id, updates) {
    const table = this.getTableById(id);
    if (!table) return null;
    if (updates.number !== undefined) table.number = String(updates.number);
    if (updates.capacity !== undefined) table.capacity = Number(updates.capacity) || 4;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveTable(table).catch(e => console.error('Error updating table in Supabase:', e.message));

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

  // ── Cafe: Menu & Categories ──────────────────────
  getCafeMenu() {
    if (!this.data.cafeMenu) this.data.cafeMenu = [];
    return this.data.cafeMenu;
  }

  getCafeMenuItemById(id) {
    return (this.data.cafeMenu || []).find(m => String(m.id) === String(id));
  }

  addCafeMenuItem(payload) {
    if (!this.data.cafeMenu) this.data.cafeMenu = [];
    const newItem = {
      id: 'cm_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      name: payload.name || '',
      category: payload.category || 'Hot Beverages',
      price: Number(payload.price) || 0,
      isVeg: payload.isVeg !== undefined ? payload.isVeg === true : true,
      description: payload.description || '',
      isAvailable: payload.isAvailable !== undefined ? payload.isAvailable : true,
    };
    this.data.cafeMenu.push(newItem);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveCafeMenuItem(newItem).catch(e => console.error('Error saving CafeMenuItem in Supabase:', e.message));

    return newItem;
  }

  updateCafeMenuItem(id, updates) {
    const item = this.getCafeMenuItemById(id);
    if (!item) return null;
    if (updates.name !== undefined) item.name = updates.name;
    if (updates.category !== undefined) item.category = updates.category;
    if (updates.price !== undefined) item.price = Number(updates.price) || 0;
    if (updates.isVeg !== undefined) item.isVeg = updates.isVeg === true;
    if (updates.description !== undefined) item.description = updates.description;
    if (updates.isAvailable !== undefined) item.isAvailable = updates.isAvailable;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveCafeMenuItem(item).catch(e => console.error('Error updating CafeMenuItem in Supabase:', e.message));

    return item;
  }

  deleteCafeMenuItem(id) {
    if (!this.data.cafeMenu) return false;
    const strId = String(id).trim();
    const idx = this.data.cafeMenu.findIndex(m => String(m.id) === strId);
    if (idx !== -1) {
      const removed = this.data.cafeMenu.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteCafeMenuItem(removed.id).catch(e => console.error('Error deleting CafeMenuItem in Supabase:', e.message));

      return true;
    }
    return false;
  }

  getCafeCategories() {
    if (!this.data.cafeCategories) this.data.cafeCategories = [];
    return this.data.cafeCategories;
  }

  addCafeCategory(name) {
    if (!this.data.cafeCategories) this.data.cafeCategories = [];
    const clean = String(name).trim();
    if (!this.data.cafeCategories.includes(clean)) {
      this.data.cafeCategories.push(clean);
      // Save to Supabase Cloud (Master)
      SupabaseMasterService.saveCafeCategory(clean).catch(e => console.error('Error saving CafeCategory in Supabase:', e.message));
    }
    return clean;
  }

  deleteCafeCategory(name) {
    if (!this.data.cafeCategories) return false;
    const clean = String(name).trim();
    const idx = this.data.cafeCategories.indexOf(clean);
    if (idx !== -1) {
      this.data.cafeCategories.splice(idx, 1);

      if (this.data.cafeMenu) {
        this.data.cafeMenu = this.data.cafeMenu.filter(
          m => String(m.category || '').trim().toLowerCase() !== clean.toLowerCase()
        );
      }

      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteCafeCategory(clean).catch(e => console.error('Error deleting CafeCategory in Supabase:', e.message));

      return true;
    }
    return false;
  }

  // ── Cafe: Orders & Billing ──────────────────────
  getCafeOrders() {
    if (!this.data.cafeOrders) this.data.cafeOrders = [];
    return this.data.cafeOrders;
  }

  createCafeOrder(payload) {
    if (!this.data.cafeOrders) this.data.cafeOrders = [];
    const items = (payload.items || []).map(it => ({
      id: it.id || '',
      name: it.name || '',
      price: Number(it.price) || 0,
      quantity: Number(it.quantity) || 1,
      isVeg: it.isVeg !== false,
    }));
    const subtotal = payload.subtotal !== undefined ? Number(payload.subtotal) : items.reduce((sum, it) => sum + (it.price * it.quantity), 0);
    const tax = 0;
    const total = payload.total !== undefined ? Number(payload.total) : subtotal;

    const newOrder = {
      id: 'cf_ord_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      orderNumber: `CF-${String(this.data.cafeOrders.length + 1).padStart(3, '0')}`,
      guestName: payload.guestName || 'Walk-in Guest',
      items,
      subtotal,
      tax,
      total,
      isPaid: payload.isPaid !== undefined ? payload.isPaid : true,
      paymentMethod: payload.paymentMethod || 'Cash',
      status: 'completed',
      createdAt: new Date().toISOString(),
    };
    this.data.cafeOrders.unshift(newOrder);

    if (this.isConnected()) {
      CafeOrder.create(newOrder).catch(e => console.error('Error saving CafeOrder in Mongo:', e.message));
    }
    return newOrder;
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

  // ── Banquet: Halls (Master - Supabase) ────────────
  getBanquetHalls() {
    if (!this.data.banquetHalls) this.data.banquetHalls = [];
    return this.data.banquetHalls;
  }

  getBanquetHallById(id) {
    return (this.data.banquetHalls || []).find(h => String(h.id) === String(id));
  }

  addBanquetHall(payload) {
    if (!this.data.banquetHalls) this.data.banquetHalls = [];
    const newHall = {
      id: 'hall_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      name: payload.name || 'New Banquet Hall',
      capacity: Number(payload.capacity) || 100,
      baseRentMorning: Number(payload.baseRentMorning) || 15000,
      baseRentEvening: Number(payload.baseRentEvening) || 25000,
      baseRentFullDay: Number(payload.baseRentFullDay) || 35000,
      amenities: Array.isArray(payload.amenities) ? payload.amenities : [],
      imageUrl: payload.imageUrl || null,
      status: payload.status || 'available',
    };
    this.data.banquetHalls.push(newHall);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveBanquetHall(newHall).catch(e => console.error('Error saving BanquetHall in Supabase:', e.message));

    return newHall;
  }

  updateBanquetHall(id, updates) {
    const hall = this.getBanquetHallById(id);
    if (!hall) return null;
    if (updates.name !== undefined) hall.name = updates.name;
    if (updates.capacity !== undefined) hall.capacity = Number(updates.capacity) || 100;
    if (updates.baseRentMorning !== undefined) hall.baseRentMorning = Number(updates.baseRentMorning) || 15000;
    if (updates.baseRentEvening !== undefined) hall.baseRentEvening = Number(updates.baseRentEvening) || 25000;
    if (updates.baseRentFullDay !== undefined) hall.baseRentFullDay = Number(updates.baseRentFullDay) || 35000;
    if (updates.amenities !== undefined) hall.amenities = Array.isArray(updates.amenities) ? updates.amenities : [];
    if (updates.status !== undefined) hall.status = updates.status;
    if (updates.imageUrl !== undefined) hall.imageUrl = updates.imageUrl;

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveBanquetHall(hall).catch(e => console.error('Error updating BanquetHall in Supabase:', e.message));

    return hall;
  }

  deleteBanquetHall(id) {
    if (!this.data.banquetHalls) return false;
    const strId = String(id).trim();
    const idx = this.data.banquetHalls.findIndex(h => String(h.id) === strId);
    if (idx !== -1) {
      const removed = this.data.banquetHalls.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteBanquetHall(removed.id).catch(e => console.error('Error deleting BanquetHall in Supabase:', e.message));
      return true;
    }
    return false;
  }

  // ── Banquet: Packages (Master - Supabase) ─────────
  getBanquetPackages() {
    if (!this.data.banquetPackages) this.data.banquetPackages = [];
    return this.data.banquetPackages;
  }

  addBanquetPackage(payload) {
    if (!this.data.banquetPackages) this.data.banquetPackages = [];
    const newPkg = {
      id: 'pkg_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      name: payload.name || 'New Package',
      pricePerPlate: Number(payload.pricePerPlate) || 400,
      isVeg: payload.isVeg !== false,
      description: payload.description || '',
      inclusions: Array.isArray(payload.inclusions) ? payload.inclusions : [],
    };
    this.data.banquetPackages.push(newPkg);

    // Save to Supabase Cloud (Master)
    SupabaseMasterService.saveBanquetPackage(newPkg).catch(e => console.error('Error saving BanquetPackage in Supabase:', e.message));

    return newPkg;
  }

  deleteBanquetPackage(id) {
    if (!this.data.banquetPackages) return false;
    const strId = String(id).trim();
    const idx = this.data.banquetPackages.findIndex(p => String(p.id) === strId);
    if (idx !== -1) {
      const removed = this.data.banquetPackages.splice(idx, 1)[0];
      // Delete from Supabase Cloud (Master)
      SupabaseMasterService.deleteBanquetPackage(removed.id).catch(e => console.error('Error deleting BanquetPackage in Supabase:', e.message));
      return true;
    }
    return false;
  }

  // ── Banquet: Bookings (Transactional - MongoDB) ───
  getBanquetBookings() {
    if (!this.data.banquetBookings) this.data.banquetBookings = [];
    return this.data.banquetBookings;
  }

  getBanquetBookingById(id) {
    return (this.data.banquetBookings || []).find(b => String(b.id) === String(id) || String(b.bookingNumber) === String(id));
  }

  createBanquetBooking(payload) {
    if (!this.data.banquetBookings) this.data.banquetBookings = [];
    const count = this.data.banquetBookings.length + 1;
    const bookingNumber = `BNQ-2026-${String(count).padStart(3, '0')}`;

    const expectedGuests = Number(payload.expectedGuests) || 100;
    const pricePerPlate = Number(payload.pricePerPlate) || 0;
    const foodTotal = payload.foodTotal !== undefined ? Number(payload.foodTotal) : (expectedGuests * pricePerPlate);
    const hallRent = Number(payload.hallRent) || 0;
    const extraCharges = Number(payload.extraCharges) || 0;
    const tax = Number(payload.tax) || 0;
    const grandTotal = payload.grandTotal !== undefined ? Number(payload.grandTotal) : (foodTotal + hallRent + extraCharges + tax);
    const advancePaid = Number(payload.advancePaid) || 0;
    const balanceDue = Math.max(0, grandTotal - advancePaid);

    const newBooking = {
      id: 'bnq_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      bookingNumber,
      hallId: payload.hallId || '',
      hallName: payload.hallName || '',
      customerName: payload.customerName || '',
      customerPhone: payload.customerPhone || '',
      customerEmail: payload.customerEmail || '',
      eventType: payload.eventType || 'Wedding',
      eventDate: payload.eventDate || new Date().toISOString().split('T')[0],
      slot: payload.slot || 'Evening',
      expectedGuests,
      packageId: payload.packageId || '',
      packageName: payload.packageName || '',
      pricePerPlate,
      foodTotal,
      hallRent,
      extraCharges,
      tax,
      grandTotal,
      advancePaid,
      balanceDue,
      status: payload.status || 'confirmed',
      notes: payload.notes || '',
      createdAt: new Date().toISOString(),
    };

    this.data.banquetBookings.unshift(newBooking);

    if (this.isConnected()) {
      BanquetBooking.create(newBooking).catch(e => console.error('Error creating BanquetBooking in Mongo:', e.message));
    }

    return newBooking;
  }

  updateBanquetBooking(id, updates) {
    const booking = this.getBanquetBookingById(id);
    if (!booking) return null;

    Object.assign(booking, updates);
    if (updates.advancePaid !== undefined || updates.grandTotal !== undefined) {
      booking.balanceDue = Math.max(0, (booking.grandTotal || 0) - (booking.advancePaid || 0));
    }

    if (this.isConnected()) {
      BanquetBooking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        updates
      ).catch(e => console.error('Error updating BanquetBooking in Mongo:', e.message));
    }

    return booking;
  }

  cancelBanquetBooking(id, reason = '') {
    const booking = this.getBanquetBookingById(id);
    if (!booking) return null;

    booking.status = 'cancelled';
    booking.notes = (booking.notes ? booking.notes + '\n' : '') + `Cancelled: ${reason}`;

    if (this.isConnected()) {
      BanquetBooking.findOneAndUpdate(
        { $or: [{ id: booking.id }, { bookingNumber: booking.bookingNumber }] },
        { status: 'cancelled', notes: booking.notes }
      ).catch(e => console.error('Error cancelling BanquetBooking in Mongo:', e.message));
    }

    return booking;
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

    // Cafe revenue from paid orders
    const paidCafeOrders = (this.data.cafeOrders || []).filter(o => o.isPaid === true);
    const cafeRevenue = paidCafeOrders.reduce((sum, o) => sum + (Number(o.total) || 0), 0);

    // Banquet revenue from active bookings
    const activeBanquetBookings = (this.data.banquetBookings || []).filter(b => b.status !== 'cancelled');
    const banquetRevenue = activeBanquetBookings.reduce((sum, b) => sum + (Number(b.advancePaid) || 0) + (Number(b.paidAmount) || 0), 0);

    const revenueToday = roomRevenue + restaurantRevenue + cafeRevenue + banquetRevenue;
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
      cafeRevenue,
      banquetRevenue,
      pendingCheckIns,
      activeGuests: occupied * 2,
    };
  }
}

export const store = new MongoBackedStore();
export default store;
