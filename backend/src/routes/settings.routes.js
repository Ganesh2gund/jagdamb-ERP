/**
 * Hotel Settings Store & Routes
 * --------------------------------
 * Persists hotel profile in Supabase (Master) and MongoDB Atlas (Backup).
 */
import { SupabaseMasterService } from '../services/supabaseService.js';

export const hotelSettings = {
  hotelName: process.env.HOTEL_NAME || 'The Grand Palace Hotel',
  hotelPhone: process.env.HOTEL_PHONE || '',
  hotelEmail: process.env.HOTEL_EMAIL || '',
  hotelAddress: process.env.HOTEL_ADDRESS || 'Near Central Station, Luxury Suites & Rooms',
};

// Sync settings from Supabase (or fallback to MongoDB) on server startup
export async function loadHotelSettingsFromDB() {
  try {
    const supaSettings = await SupabaseMasterService.getSettings();
    if (supaSettings) {
      if (supaSettings.hotelName) hotelSettings.hotelName = supaSettings.hotelName;
      if (supaSettings.hotelPhone) hotelSettings.hotelPhone = supaSettings.hotelPhone;
      if (supaSettings.hotelEmail) hotelSettings.hotelEmail = supaSettings.hotelEmail;
      if (supaSettings.hotelAddress) hotelSettings.hotelAddress = supaSettings.hotelAddress;
      console.log('✅ Hotel settings loaded from Supabase Cloud.');
      return;
    }
  } catch (err) {
    console.warn('⚠️ Supabase settings load warning:', err.message);
  }
}

export default async function settingsRoutes(fastify) {
  fastify.get('/', async (request, reply) => {
    return reply.send({
      success: true,
      settings: {
        hotelName: hotelSettings.hotelName,
        hotelPhone: hotelSettings.hotelPhone,
        hotelEmail: hotelSettings.hotelEmail,
        hotelAddress: hotelSettings.hotelAddress,
      },
    });
  });

  fastify.put('/', async (request, reply) => {
    const body = request.body ?? {};

    const allowed = ['hotelName', 'hotelPhone', 'hotelEmail', 'hotelAddress'];
    for (const key of allowed) {
      if (body[key] !== undefined && body[key] !== null) {
        hotelSettings[key] = body[key];
      }
    }

    // Save to Supabase (Master Permanent)
    SupabaseMasterService.saveSettings(hotelSettings).catch(e =>
      console.error('Error saving settings to Supabase:', e.message)
    );

    return reply.send({
      success: true,
      message: 'Settings updated successfully',
    });
  });
}
