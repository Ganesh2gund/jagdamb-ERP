import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_erp/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsAppHelper Phone Sanitization', () {
    test('10 digit Indian number gets 91 prepended', () {
      expect(WhatsAppHelper.sanitizePhoneNumber('9876543210'), '919876543210');
    });

    test('Number with spaces, dashes, brackets, + gets cleaned', () {
      expect(WhatsAppHelper.sanitizePhoneNumber('+91 (987) 654-3210'), '919876543210');
    });

    test('11 digit number with leading 0 converts to 91', () {
      expect(WhatsAppHelper.sanitizePhoneNumber('09876543210'), '919876543210');
    });

    test('Empty or null returns null', () {
      expect(WhatsAppHelper.sanitizePhoneNumber(''), isNull);
      expect(WhatsAppHelper.sanitizePhoneNumber('   '), isNull);
      expect(WhatsAppHelper.sanitizePhoneNumber(null), isNull);
    });

    test('Short invalid numbers return empty string indicator', () {
      expect(WhatsAppHelper.sanitizePhoneNumber('12345'), '');
    });
  });

  group('WhatsAppHelper Message Generation', () {
    test('Matches exact requested format', () {
      final msg = WhatsAppHelper.buildInvoiceMessage(
        customerName: 'Rahul Sharma',
        invoiceNo: 'INV-123456',
        totalAmount: 4500,
      );

      final expected = 'Hello Rahul Sharma,\n\n'
          'Thank you for choosing our hotel.\n\n'
          'Your invoice INV-123456 has been generated successfully.\n\n'
          'Invoice Amount: ₹4500\n\n'
          'Thank you for visiting us.';

      expect(msg, expected);
    });
  });
}
