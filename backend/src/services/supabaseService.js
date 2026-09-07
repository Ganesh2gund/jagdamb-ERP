import { supabase } from '../supabase.js';

export class SupabaseMasterService {
  // ── 1. Rooms ──────────────────────────────────────────────────
  static async getRooms() {
    try {
      const { data, error } = await supabase.from('rooms').select('*').order('room_number', { ascending: true });
      if (error) throw error;
      return (data || []).map(r => ({
        id: r.id,
        number: r.number || r.room_number,
        floor: r.floor || 1,
        type: r.type || 'standard',
        pricePerNight: Number(r.price_per_night || r.price) || 1000,
        status: r.status || 'available',
        amenities: r.amenities || [],
        maxGuests: r.max_guests || 2,
        imageUrl: r.image_url || null,
        currentGuestName: r.current_guest_name || null,
        currentGuestId: r.current_guest_id || null,
        currentBookingId: r.current_booking_id || null,
        checkInDate: r.check_in_date || null,
        checkOutDate: r.check_out_date || null,
        maintenanceNote: r.maintenance_note || null,
      }));
    } catch (err) {
      console.error('❌ Supabase getRooms error:', err.message);
      return null;
    }
  }

  static async saveRoom(room) {
    try {
      const row = {
        id: room.id,
        room_number: String(room.number || room.room_number),
        number: String(room.number || room.room_number),
        floor: Number(room.floor) || 1,
        type: room.type || 'standard',
        price: Number(room.pricePerNight || room.price) || 1000,
        price_per_night: Number(room.pricePerNight || room.price) || 1000,
        status: room.status || 'available',
        amenities: room.amenities || [],
        max_guests: Number(room.maxGuests) || 2,
        image_url: room.imageUrl || null,
        current_guest_name: room.currentGuestName || null,
        current_guest_id: room.currentGuestId || null,
        current_booking_id: room.currentBookingId || null,
        check_in_date: room.checkInDate || null,
        check_out_date: room.checkOutDate || null,
        maintenance_note: room.maintenanceNote || null,
        updated_at: new Date().toISOString(),
      };
      const { error } = await supabase.from('rooms').upsert(row);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase saveRoom error:', err.message);
      return false;
    }
  }

  static async deleteRoom(id) {
    try {
      const { error } = await supabase.from('rooms').delete().eq('id', id);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase deleteRoom error:', err.message);
      return false;
    }
  }

  // ── 2. Menu Items ─────────────────────────────────────────────
  static async getMenu() {
    try {
      const { data, error } = await supabase.from('menu_items').select('*').order('name', { ascending: true });
      if (error) throw error;
      return (data || []).map(m => ({
        id: m.id,
        name: m.name,
        category: m.category,
        price: Number(m.price) || 0,
        isVeg: m.is_veg === true,
        description: m.description || '',
        isAvailable: m.is_available !== false,
      }));
    } catch (err) {
      console.error('❌ Supabase getMenu error:', err.message);
      return null;
    }
  }

  static async saveMenuItem(item) {
    try {
      const row = {
        id: item.id,
        name: item.name,
        category: item.category,
        price: Number(item.price) || 0,
        is_veg: item.isVeg === true,
        description: item.description || '',
        is_available: item.isAvailable !== false,
        updated_at: new Date().toISOString(),
      };
      const { error } = await supabase.from('menu_items').upsert(row);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase saveMenuItem error:', err.message);
      return false;
    }
  }

  static async deleteMenuItem(id) {
    try {
      const { error } = await supabase.from('menu_items').delete().eq('id', id);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase deleteMenuItem error:', err.message);
      return false;
    }
  }

  // ── 3. Categories ─────────────────────────────────────────────
  static async getCategories() {
    try {
      const { data, error } = await supabase.from('restaurant_categories').select('name').order('name', { ascending: true });
      if (error) throw error;
      return (data || []).map(c => c.name);
    } catch (err) {
      console.error('❌ Supabase getCategories error:', err.message);
      return null;
    }
  }

  static async saveCategory(name) {
    try {
      const id = 'cat_' + name.toLowerCase().replace(/[^a-z0-9]/g, '_');
      const { error } = await supabase.from('restaurant_categories').upsert({ id, name });
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase saveCategory error:', err.message);
      return false;
    }
  }

  static async deleteCategory(name) {
    try {
      const { error } = await supabase.from('restaurant_categories').delete().eq('name', name);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase deleteCategory error:', err.message);
      return false;
    }
  }

  // ── 4. Tables ─────────────────────────────────────────────────
  static async getTables() {
    try {
      const { data, error } = await supabase.from('restaurant_tables').select('*').order('table_number', { ascending: true });
      if (error) throw error;
      return (data || []).map(t => ({
        id: t.id,
        number: t.table_number,
        capacity: Number(t.capacity) || 4,
        status: t.status || 'available',
      }));
    } catch (err) {
      console.error('❌ Supabase getTables error:', err.message);
      return null;
    }
  }

  static async saveTable(table) {
    try {
      const row = {
        id: table.id,
        table_number: String(table.number),
        capacity: Number(table.capacity) || 4,
        status: table.status || 'available',
      };
      const { error } = await supabase.from('restaurant_tables').upsert(row);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase saveTable error:', err.message);
      return false;
    }
  }

  static async deleteTable(id) {
    try {
      const { error } = await supabase.from('restaurant_tables').delete().eq('id', id);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase deleteTable error:', err.message);
      return false;
    }
  }

  // ── 5. Hotel Settings ─────────────────────────────────────────
  static async getSettings() {
    try {
      const { data, error } = await supabase.from('hotel_settings').select('*').eq('id', 'default').maybeSingle();
      if (error) throw error;
      if (!data) return null;
      return {
        hotelName: data.name,
        hotelAddress: data.address,
        hotelPhone: data.phone,
        hotelEmail: data.email,
      };
    } catch (err) {
      console.error('❌ Supabase getSettings error:', err.message);
      return null;
    }
  }

  static async saveSettings(settings) {
    try {
      const row = {
        id: 'default',
        name: settings.hotelName || 'Hotel ERP',
        address: settings.hotelAddress || '',
        phone: settings.hotelPhone || '',
        email: settings.hotelEmail || '',
        updated_at: new Date().toISOString(),
      };
      const { error } = await supabase.from('hotel_settings').upsert(row);
      if (error) throw error;
      return true;
    } catch (err) {
      console.error('❌ Supabase saveSettings error:', err.message);
      return false;
    }
  }
}
