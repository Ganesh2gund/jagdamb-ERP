/**
 * Hotel Settings Store & Routes
 * --------------------------------
 * Stores hotel profile in memory.
 * Future: persist to database (one row settings table).
 */

// In-memory settings store
export const hotelSettings = {
  // Hotel Profile
  hotelName: process.env.HOTEL_NAME || 'The Grand Palace Hotel',
  hotelPhone: process.env.HOTEL_PHONE || '',
  hotelEmail: process.env.HOTEL_EMAIL || '',
  hotelAddress: process.env.HOTEL_ADDRESS || 'Near Central Station, Luxury Suites & Rooms',
};

export default async function settingsRoutes(fastify) {
  /**
   * GET /api/settings
   * Returns current hotel profile settings
   */
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

  /**
   * PUT /api/settings
   * Update hotel profile settings.
   * Body: { hotelName?, hotelPhone?, hotelEmail?, hotelAddress? }
   */
  fastify.put('/', async (request, reply) => {
    const body = request.body ?? {};

    const allowed = ['hotelName', 'hotelPhone', 'hotelEmail', 'hotelAddress'];
    for (const key of allowed) {
      if (body[key] !== undefined && body[key] !== null) {
        hotelSettings[key] = body[key];
      }
    }

    return reply.send({
      success: true,
      message: 'Settings updated successfully',
    });
  });
}
