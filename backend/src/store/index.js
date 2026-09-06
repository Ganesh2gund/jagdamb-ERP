import { seedData } from './seedData.js';

// Deep clone seedData to allow mutable in-memory store
class MemoryStore {
  constructor() {
    this.data = JSON.parse(JSON.stringify(seedData));
  }

  // Auth
  validateAdmin(email, password) {
    return email === 'tejas@gmail.com' && password === 'tejas4010';
  }

  // Rooms
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
    return room;
  }

  checkOutRoom(roomId) {
    return this.updateRoomStatus(roomId, 'available');
  }

  // Create a new room (Admin)
  createRoom(payload) {
    const newRoom = {
      id: 'r' + payload.number,
      ...payload,
    };
    this.data.rooms.push(newRoom);
    return newRoom;
  }

  // Update existing room details (Admin)
  updateRoom(id, updates) {
    const room = this.getRoomById(id);
    if (!room) return null;
    const allowed = ['number', 'floor', 'type', 'pricePerNight', 'amenities', 'maxGuests', 'imageUrl', 'maintenanceNote'];
    for (const key of allowed) {
      if (updates[key] !== undefined) room[key] = updates[key];
    }
    return room;
  }

  // Delete a room (Admin)
  deleteRoom(id) {
    const idx = this.data.rooms.findIndex(r => r.id === id || r.number === id);
    if (idx !== -1) this.data.rooms.splice(idx, 1);
  }

  // Bookings
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
      ...bookingPayload
    };
    this.data.bookings.unshift(newBooking);
    
    // Update room status to reserved
    const room = this.getRoomById(newBooking.roomId);
    if (room && room.status === 'available') {
      room.status = 'reserved';
      room.currentGuestName = newBooking.guestName;
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
    }
    return booking;
  }

  updateBookingPayment(id, paymentStatus, paidAmount) {
    const booking = this.getBookingById(id);
    if (!booking) return null;
    if (paymentStatus) booking.paymentStatus = paymentStatus;
    if (paidAmount !== undefined) booking.paidAmount = Number(paidAmount);
    return booking;
  }

  updateBooking(id, updates) {
    const booking = this.getBookingById(id);
    if (!booking) return null;

    // If room is changed, adjust room statuses
    if (updates.roomId && updates.roomId !== booking.roomId) {
      const oldRoom = this.getRoomById(booking.roomId);
      if (oldRoom && oldRoom.status === 'reserved') {
        oldRoom.status = 'available';
        delete oldRoom.currentGuestName;
        delete oldRoom.currentBookingId;
      }
      const newRoom = this.getRoomById(updates.roomId);
      if (newRoom && newRoom.status === 'available') {
        newRoom.status = 'reserved';
        newRoom.currentGuestName = updates.guestName || booking.guestName;
        newRoom.currentBookingId = booking.id;
      }
    }

    // Merge updates
    Object.assign(booking, updates);
    return booking;
  }

  cancelBooking(id, reason) {
    const booking = this.getBookingById(id);
    if (!booking) return null;

    booking.status = 'cancelled';
    booking.cancellationReason = reason || 'Cancelled by admin';

    // Release room back to available if it was reserved or occupied by this booking
    const room = this.getRoomById(booking.roomId);
    if (room && (room.status === 'reserved' || room.status === 'occupied')) {
      room.status = 'available';
      delete room.currentGuestName;
      delete room.currentGuestId;
      delete room.currentBookingId;
      delete room.checkInDate;
      delete room.checkOutDate;
    }

    return booking;
  }

  // Guests
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
      ...payload
    };
    this.data.guests.push(newGuest);
    return newGuest;
  }

  // Restaurant
  getMenu() {
    if (!this.data.restaurantMenu) this.data.restaurantMenu = [];
    return this.data.restaurantMenu;
  }

  getOrders() {
    if (!this.data.restaurantOrders) this.data.restaurantOrders = [];
    return this.data.restaurantOrders;
  }

  createOrder(orderPayload) {
    const newOrder = {
      id: 'ord' + (this.data.restaurantOrders.length + 1),
      orderNumber: `ORD-${this.data.restaurantOrders.length + 101}`,
      createdAt: new Date().toISOString(),
      status: 'received',
      kotNumber: `KOT-${this.data.restaurantOrders.length + 201}`,
      isPaid: orderPayload.isPaid || false,
      paymentMethod: orderPayload.paymentMethod || null,
      ...orderPayload
    };
    this.data.restaurantOrders.unshift(newOrder);

    // If dine-in order with a table, mark table occupied
    if (orderPayload.target && orderPayload.target.toLowerCase().includes('table')) {
      const table = this.data.restaurantTables?.find(t => 
        t.number.toLowerCase() === orderPayload.target.toLowerCase() ||
        t.id.toLowerCase() === orderPayload.target.toLowerCase()
      );
      if (table) {
        table.status = 'occupied';
        table.currentOrderId = newOrder.id;
        table.currentBillAmount = newOrder.total;
      }
    }

    // If room delivery, optionally link to active booking
    if (orderPayload.type === 'roomDelivery' && orderPayload.target) {
      const roomNum = orderPayload.target.replace(/room\s*/i, '').trim();
      const room = this.data.rooms.find(r => r.number === roomNum || r.id === roomNum);
      if (room && room.currentBookingId) {
        newOrder.bookingId = room.currentBookingId;
        newOrder.roomId = room.id;
        newOrder.guestName = room.currentGuestName;
      }
    }

    return newOrder;
  }

  updateOrderStatus(orderId, status) {
    const order = this.data.restaurantOrders.find(o => o.id === orderId);
    if (!order) return null;
    order.status = status;
    return order;
  }

  // Restaurant Menu Management (Admin)
  addMenuItem(payload) {
    const newItem = {
      id: 'm' + (this.data.restaurantMenu.length + 1),
      isAvailable: true,
      ...payload,
    };
    this.data.restaurantMenu.push(newItem);
    return newItem;
  }

  updateMenuItem(id, updates) {
    const item = this.data.restaurantMenu.find(m => m.id === id);
    if (!item) return null;
    Object.assign(item, updates);
    return item;
  }

  deleteMenuItem(id) {
    const idx = this.data.restaurantMenu.findIndex(m => m.id === id);
    if (idx !== -1) {
      this.data.restaurantMenu.splice(idx, 1);
      return true;
    }
    return false;
  }

  // Restaurant Tables Management
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
      id: 'tbl_' + Date.now(),
      number: String(payload.number || (this.data.restaurantTables.length + 1)),
      capacity: Number(payload.capacity) || 4,
    };
    this.data.restaurantTables.push(newTable);
    return newTable;
  }

  updateTable(id, updates) {
    const table = this.getTableById(id);
    if (!table) return null;
    if (updates.number !== undefined) table.number = String(updates.number);
    if (updates.capacity !== undefined) table.capacity = Number(updates.capacity);
    return table;
  }

  deleteTable(id) {
    if (!this.data.restaurantTables) return false;
    const idx = this.data.restaurantTables.findIndex(t => String(t.id) === String(id) || String(t.number) === String(id));
    if (idx !== -1) {
      this.data.restaurantTables.splice(idx, 1);
      return true;
    }
    return false;
  }

  // Restaurant Categories Management
  getCategories() {
    if (!this.data.restaurantCategories) this.data.restaurantCategories = [];
    return this.data.restaurantCategories;
  }

  addCategory(name) {
    const categories = this.getCategories();
    const clean = String(name || '').trim();
    if (!clean) return null;
    if (!categories.includes(clean)) {
      categories.push(clean);
    }
    return clean;
  }

  deleteCategory(name) {
    const categories = this.getCategories();
    const clean = String(name || '').trim();
    const idx = categories.indexOf(clean);
    if (idx !== -1) {
      categories.splice(idx, 1);
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
    return table;
  }

  // Settle Walk-in / Table Order
  settleOrder(orderId, paymentMethod = 'Cash', tax = 0, grandTotal = 0) {
    const order = this.data.restaurantOrders.find(o => o.id === orderId);
    if (!order) return null;

    order.isPaid = true;
    order.paymentMethod = paymentMethod;
    if (tax) order.tax = tax;
    if (grandTotal) order.total = grandTotal;
    order.status = 'served';

    // Clear linked table
    if (order.target) {
      const table = (this.data.restaurantTables || []).find(t => 
        t.number.toLowerCase() === order.target.toLowerCase() || t.id.toLowerCase() === order.target.toLowerCase()
      );
      if (table) {
        table.status = 'available';
        table.currentOrderId = null;
        table.currentBillAmount = 0;
      }
    }

    return order;
  }

  // Housekeeping
  getHousekeepingTasks() {
    return this.data.housekeepingTasks;
  }

  updateHousekeepingTask(id, updates) {
    const task = this.data.housekeepingTasks.find(t => t.id === id);
    if (!task) return null;
    Object.assign(task, updates);
    return task;
  }

  // Inventory
  getInventory() {
    return this.data.inventoryItems;
  }

  updateInventoryStock(id, newStock) {
    const item = this.data.inventoryItems.find(i => i.id === id);
    if (!item) return null;
    item.currentStock = newStock;
    item.isLowStock = item.currentStock <= item.minStock;
    return item;
  }

  // Staff
  getStaff() {
    return this.data.staff;
  }

  toggleStaffAttendance(id) {
    const staff = this.data.staff.find(s => s.id === id);
    if (!staff) return null;
    staff.presentToday = !staff.presentToday;
    return staff;
  }

  // Expenses
  getExpenses() {
    return this.data.expenses;
  }

  addExpense(payload) {
    const newExpense = {
      id: payload.id || ('exp' + (this.data.expenses.length + 1)),
      date: payload.date || new Date().toISOString().split('T')[0],
      ...payload
    };
    this.data.expenses.unshift(newExpense);
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
      return newExp;
    }
    if (updates.category !== undefined) exp.category = updates.category;
    if (updates.amount !== undefined) exp.amount = Number(updates.amount) || exp.amount;
    if (updates.description !== undefined) exp.description = updates.description;
    if (updates.paymentMethod !== undefined) exp.paymentMethod = updates.paymentMethod;
    if (updates.notes !== undefined) exp.notes = updates.notes;
    if (updates.date !== undefined) exp.date = updates.date;
    return exp;
  }

  deleteExpense(id) {
    if (!this.data.expenses) return true;
    const strId = String(id).trim().toLowerCase();
    const idx = this.data.expenses.findIndex(e => String(e.id).trim().toLowerCase() === strId);
    if (idx !== -1) {
      this.data.expenses.splice(idx, 1);
    }
    return true;
  }

  // Maintenance
  getMaintenance() {
    return this.data.maintenance;
  }

  addMaintenance(payload) {
    const newMnt = {
      id: 'mnt' + (this.data.maintenance.length + 1),
      createdAt: new Date().toISOString(),
      status: 'Reported',
      ...payload
    };
    this.data.maintenance.unshift(newMnt);
    return newMnt;
  }

  updateMaintenance(id, updates) {
    const mnt = this.data.maintenance.find(m => m.id === id);
    if (!mnt) return null;
    Object.assign(mnt, updates);
    return mnt;
  }

  // Notifications
  getNotifications() {
    return this.data.notifications;
  }

  markNotificationRead(id) {
    const notif = this.data.notifications.find(n => n.id === id);
    if (!notif) return null;
    notif.isRead = true;
    return notif;
  }

  // Restaurant: Tables
  getTables() {
    if (!this.data.restaurantTables) this.data.restaurantTables = [];
    return this.data.restaurantTables;
  }

  createTable(payload) {
    if (!this.data.restaurantTables) this.data.restaurantTables = [];
    const newTable = {
      id: 'tbl_' + Date.now() + '_' + Math.random().toString(36).substring(2, 6),
      number: String(payload.number),
      capacity: Number(payload.capacity) || 4,
    };
    this.data.restaurantTables.push(newTable);
    return newTable;
  }

  updateTable(id, updates) {
    if (!this.data.restaurantTables) return null;
    const strId = String(id).trim();
    const table = this.data.restaurantTables.find(t => String(t.id) === strId || String(t.number) === strId);
    if (!table) return null;
    if (updates.number !== undefined) table.number = String(updates.number);
    if (updates.capacity !== undefined) table.capacity = Number(updates.capacity) || 4;
    return table;
  }

  deleteTable(id) {
    if (!this.data.restaurantTables) return false;
    const strId = String(id).trim();
    const idx = this.data.restaurantTables.findIndex(t => String(t.id) === strId || String(t.number) === strId);
    if (idx !== -1) {
      this.data.restaurantTables.splice(idx, 1);
      return true;
    }
    return false;
  }

  updateTableStatus(id, status, currentOrderId, currentBillAmount) {
    if (!this.data.restaurantTables) return null;
    const strId = String(id).trim();
    const table = this.data.restaurantTables.find(t => String(t.id) === strId || String(t.number) === strId);
    if (!table) return null;
    table.status = status;
    if (currentOrderId !== undefined) table.currentOrderId = currentOrderId;
    if (currentBillAmount !== undefined) table.currentBillAmount = currentBillAmount;
    return table;
  }

  // Restaurant: Menu & Categories
  getCategories() {
    if (!this.data.restaurantCategories) this.data.restaurantCategories = [];
    return this.data.restaurantCategories;
  }

  addCategory(name) {
    if (!this.data.restaurantCategories) this.data.restaurantCategories = [];
    const clean = String(name).trim();
    if (!this.data.restaurantCategories.includes(clean)) {
      this.data.restaurantCategories.push(clean);
    }
    return clean;
  }

  deleteCategory(name) {
    if (!this.data.restaurantCategories) return false;
    const clean = String(name).trim();
    const idx = this.data.restaurantCategories.indexOf(clean);
    if (idx !== -1) {
      this.data.restaurantCategories.splice(idx, 1);
      return true;
    }
    return false;
  }

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
    };
    this.data.restaurantMenu.push(newItem);
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
    return item;
  }

  deleteMenuItem(id) {
    if (!this.data.restaurantMenu) return false;
    const strId = String(id).trim();
    const idx = this.data.restaurantMenu.findIndex(m => String(m.id) === strId);
    if (idx !== -1) {
      this.data.restaurantMenu.splice(idx, 1);
      return true;
    }
    return false;
  }

  // Restaurant: Orders & Settlement
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
      createdAt: new Date().toISOString(),
    };
    this.data.restaurantOrders.unshift(newOrder);
    return newOrder;
  }

  updateOrderStatus(id, status) {
    if (!this.data.restaurantOrders) return null;
    const strId = String(id).trim();
    const order = this.data.restaurantOrders.find(o => String(o.id) === strId || String(o.orderNumber) === strId);
    if (!order) return null;
    order.status = status;
    return order;
  }

  settleOrder(id, paymentMethod, tax, grandTotal) {
    if (!this.data.restaurantOrders) return null;
    const strId = String(id).trim();
    const order = this.data.restaurantOrders.find(o => String(o.id) === strId || String(o.orderNumber) === strId);
    if (!order) return null;
    order.isPaid = true;
    order.paymentMethod = paymentMethod || 'Cash';
    if (tax !== undefined) order.tax = tax;
    if (grandTotal !== undefined) order.total = grandTotal;
    return order;
  }

  // Dashboard Stats
  getDashboardSummary() {
    const rooms = this.data.rooms;
    const totalRooms = rooms.length;
    const occupied = rooms.filter(r => r.status === 'occupied').length;
    const available = rooms.filter(r => r.status === 'available').length;
    const cleaning = rooms.filter(r => r.status === 'cleaning').length;
    const maintenance = rooms.filter(r => r.status === 'maintenance').length;
    const reserved = rooms.filter(r => r.status === 'reserved').length;
    const occupancyRate = totalRooms > 0 ? Math.round((occupied / totalRooms) * 100) : 0;

    const todayBookings = this.data.bookings.filter(b => b.status === 'checkedIn');
    const revenueToday = todayBookings.reduce((sum, b) => sum + (b.advancePaid || 0), 0) + 14500; // plus pos
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
      pendingCheckIns,
      activeGuests: occupied * 2,
    };
  }
}

export const store = new MemoryStore();
