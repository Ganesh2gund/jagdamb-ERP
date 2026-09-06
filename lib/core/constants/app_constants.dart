class AppConstants {
  static const String appName = 'Hotel ERP';
  static const String appSubtitle = 'Manage your hotel. Smarter.';
  static const String hotelName = 'The Grand Palace Hotel';
  static const String hotelPhone = '+91 98765 43210';
  static const String hotelEmail = 'info@grandpalace.com';
  static const String hotelAddress = '14, MG Road, Bengaluru, Karnataka 560001';
  static const String hotelGST = '29ABCDE1234F1Z5';

  // Auth
  static const String adminEmail = 'tejas@gmail.com';
  static const String adminPassword = 'tejas4010';
  static const String adminName = 'Tejas Sharma';

  // Shared prefs keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAdminEmail = 'admin_email';
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String rooms = '/rooms';
  static const String roomDetail = '/rooms/:id';
  static const String bookings = '/bookings';
  static const String newBooking = '/bookings/new';
  static const String bookingDetail = '/bookings/:id';
  static const String checkIn = '/check-in';
  static const String checkOut = '/check-out';
  static const String guests = '/guests';
  static const String guestDetail = '/guests/:id';
  static const String billing = '/billing/:id';
  static const String payments = '/payments';
  static const String restaurant = '/restaurant';
  static const String housekeeping = '/housekeeping';
  static const String inventory = '/inventory';
  static const String expenses = '/expenses';
  static const String staff = '/staff';
  static const String maintenance = '/maintenance';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String more = '/more';
}
