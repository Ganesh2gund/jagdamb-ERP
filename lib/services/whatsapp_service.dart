import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Result model for WhatsApp sending operation.
///
/// Future DB fields (when database is added, these map directly):
///   - whatsappSent        → Boolean column in invoices/bookings table
///   - whatsappSentAt      → DateTime column
///   - whatsappMessageId   → String column (Meta message ID)
///   - whatsappError       → String column (last error message)
class WhatsAppResult {
  final bool success;
  final bool whatsappSent;
  final String? whatsappMessageId;
  final DateTime? whatsappSentAt;
  final String? whatsappError;
  final String message;

  const WhatsAppResult({
    required this.success,
    required this.whatsappSent,
    this.whatsappMessageId,
    this.whatsappSentAt,
    this.whatsappError,
    required this.message,
  });

  factory WhatsAppResult.fromJson(Map<String, dynamic> json) {
    return WhatsAppResult(
      success: json['success'] == true,
      whatsappSent: json['whatsappSent'] == true,
      whatsappMessageId: json['whatsappMessageId']?.toString(),
      whatsappSentAt: json['whatsappSentAt'] != null
          ? DateTime.tryParse(json['whatsappSentAt'].toString())
          : null,
      whatsappError: json['whatsappError']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }

  /// Quick factory for local/client-side errors
  factory WhatsAppResult.localError(String error) {
    return WhatsAppResult(
      success: false,
      whatsappSent: false,
      whatsappError: error,
      message: error,
    );
  }
}

/// Parameters for sending a WhatsApp invoice.
class WhatsAppInvoiceParams {
  final String phone;
  final String guestName;
  final String invoiceNumber;
  final double totalAmount;
  final double advanceAmount;
  final double balanceDue;
  final String? hotelName;

  const WhatsAppInvoiceParams({
    required this.phone,
    required this.guestName,
    required this.invoiceNumber,
    required this.totalAmount,
    this.advanceAmount = 0.0,
    this.balanceDue = 0.0,
    this.hotelName,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'guestName': guestName,
        'invoiceNumber': invoiceNumber,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'balanceDue': balanceDue,
        if (hotelName != null) 'hotelName': hotelName,
      };
}

/// Service for WhatsApp invoice sending.
/// Communicates with the Fastify backend WhatsApp API endpoint.
class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._internal();
  WhatsAppService._internal();

  final _client = ApiClient.instance;

  /// Validates and formats a phone number via backend.
  /// Returns formatted number (e.g. "+919876543210") or null if invalid.
  Future<String?> validateAndFormatNumber(String phone) async {
    try {
      final result = await _client.post(
        '/whatsapp/validate-number',
        body: {'phone': phone},
      );
      if (result is Map && result['valid'] == true) {
        return result['formatted']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('WhatsApp validateNumber error: $e');
      return null;
    }
  }

  /// Sends invoice details via WhatsApp message.
  ///
  /// IMPORTANT: Even if this fails, the bill itself is unaffected.
  /// Always handle the result gracefully in the UI.
  Future<WhatsAppResult> sendInvoice(WhatsAppInvoiceParams params) async {
    try {
      final response = await _client.post(
        '/whatsapp/send-invoice',
        body: params.toJson(),
      );

      if (response is Map<String, dynamic>) {
        return WhatsAppResult.fromJson(response);
      }

      return WhatsAppResult.localError('Unexpected response from server');
    } on ApiException catch (e) {
      // API returned an error — but invoice still exists
      return WhatsAppResult.localError(e.message);
    } catch (e) {
      return WhatsAppResult.localError('Could not connect to server: $e');
    }
  }
}
