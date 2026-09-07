import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_erp/services/report_pdf_service.dart';

void main() {
  test('generate10DayReportPdf produces valid PDF bytes without errors', () async {
    final mockData = {
      'hotel': {
        'name': 'The Grand Palace Hotel',
        'address': 'MG Road, Pune',
        'phone': '9876543210',
        'email': 'contact@grandpalace.com',
      },
      'period': {
        'cycleNumber': 5,
        'startDate': '2026-09-07T14:01:04.959',
        'endDate': '2026-09-17T14:01:04.959',
      },
      'summary': {
        'roomRevenue': 1000.0,
        'restaurantRevenue': 0.0,
        'totalRevenue': 1000.0,
        'totalExpenses': 2000.0,
        'netProfit': -1000.0,
      },
      'bookings': [
        {
          'bookingNumber': 'BK-2026-001',
          'guestName': 'Raju',
          'guestPhone': '9876543211',
          'roomNumber': '10',
          'checkInDate': '2026-09-07T13:57:41.393',
          'checkOutDate': '2026-09-08T10:00:00.000',
          'totalAmount': 1000.0,
          'paidAmount': 1000.0,
          'status': 'checkedOut',
        }
      ],
      'orders': [],
      'expenses': [
        {
          'id': 'exp-1',
          'date': '2026-09-07T13:57:02.944',
          'category': 'Electricity',
          'description': 'Hotel Bill',
          'amount': 2000.0,
          'paymentMethod': 'Cash',
        }
      ],
    };

    final bytes = await ReportPdfService.generate10DayReportPdf(mockData);
    expect(bytes, isNotNull);
    expect(bytes.isNotEmpty, isTrue);
  });
}
