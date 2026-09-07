import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_printer.dart';

/// Helper for client-side direct WhatsApp sending via deep link (wa.me).
/// No database, backend, or WhatsApp Cloud API required.
class WhatsAppHelper {
  /// Cleans and formats phone number for WhatsApp deep link.
  /// - Strips spaces, +, -, brackets, and any non-digit characters.
  /// - Prepends '91' if it's a 10-digit Indian number.
  /// - Handles leading '0' for 11-digit numbers (e.g. 09876543210 -> 919876543210).
  /// - Returns clean digits string or null if empty / invalid.
  static String? sanitizePhoneNumber(String? rawPhone) {
    if (rawPhone == null) return null;
    final trimmed = rawPhone.trim();
    if (trimmed.isEmpty) return null;

    // Strip all non-digit characters (including +, spaces, -, (, ))
    String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    // Handle 11 digits with leading 0 (common in India e.g. 09876543210)
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '91${digits.substring(1)}';
    } else if (digits.length == 10) {
      // 10 digits without country code -> add 91
      digits = '91$digits';
    }

    // Standard phone number validation:
    // With country code, valid phone numbers are typically 10 to 15 digits.
    if (digits.length < 10 || digits.length > 15) {
      return ''; // Indicator for invalid phone number
    }

    return digits;
  }

  /// Builds a real, professional Bill / Receipt formatted message for WhatsApp
  static String buildInvoiceMessage({
    required String customerName,
    required String invoiceNo,
    required double totalAmount,
    String? hotelName,
    String? roomOrTable,
    List<String>? items,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? date,
  }) {
    final name = customerName.trim().isEmpty ? 'Guest' : customerName.trim();
    final hName = (hotelName != null && hotelName.trim().isNotEmpty)
        ? hotelName.trim()
        : (WebPrinter.hotelName.trim().isNotEmpty ? WebPrinter.hotelName.trim() : 'Hotel Jagdamb');
    final amountStr = totalAmount.truncateToDouble() == totalAmount
        ? totalAmount.toInt().toString()
        : totalAmount.toStringAsFixed(2);
    final d = date ?? DateTime.now();
    final day = d.day.toString().padLeft(2, '0');
    final mon = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1];
    final yr = d.year;
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final dateStr = '$day $mon $yr, $hour:$min $ampm';

    final buffer = StringBuffer();
    buffer.writeln('🧾 *${hName.toUpperCase()}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('         *TAX INVOICE / बिल*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*बिल सं. (Bill No):* #$invoiceNo');
    buffer.writeln('*दिनांक (Date):* $dateStr');
    buffer.writeln('*ग्राहक (Guest):* $name');
    if (roomOrTable != null && roomOrTable.trim().isNotEmpty) {
      buffer.writeln('*स्थान (Room/Table):* $roomOrTable');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');

    if (items != null && items.isNotEmpty) {
      buffer.writeln('*ऑर्डर विवरण (Items):*');
      for (final it in items) {
        buffer.writeln('• $it');
      }
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    }

    buffer.writeln('*कुल राशि (Total Amount):* ₹$amountStr');
    final pStatus = paymentStatus ?? 'PAID (पूर्ण भुगतान)';
    final pMethod = (paymentMethod != null && paymentMethod.trim().isNotEmpty) ? ' ($paymentMethod)' : '';
    buffer.writeln('*भुगतान स्थिति (Status):* ✅ *$pStatus$pMethod*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🙏 *धन्यवाद! दोबारा पधारें।*');
    buffer.write('_Thank you for visiting! Have a wonderful day._');

    return buffer.toString();
  }

  /// Direct WhatsApp launcher.
  /// Validates input, formats message as a real receipt, opens WhatsApp deep-link.
  static Future<bool> openWhatsApp({
    required BuildContext context,
    required String? rawPhone,
    required String customerName,
    required String invoiceNo,
    required double totalAmount,
    String? hotelName,
    String? roomOrTable,
    List<String>? items,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? date,
  }) async {
    final raw = rawPhone?.trim() ?? '';
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer WhatsApp number.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final formattedPhone = sanitizePhoneNumber(raw);
    if (formattedPhone == null || formattedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid WhatsApp number.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final message = buildInvoiceMessage(
      customerName: customerName,
      invoiceNo: invoiceNo,
      totalAmount: totalAmount,
      hotelName: hotelName,
      roomOrTable: roomOrTable,
      items: items,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      date: date,
    );

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    final uri = Uri.parse(urlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try fallback to platformDefault
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp is not installed on this device.'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }
}
