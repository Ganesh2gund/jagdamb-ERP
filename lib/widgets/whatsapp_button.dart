import 'package:flutter/material.dart';
import '../core/utils/whatsapp_helper.dart';

/// Direct WhatsApp Invoice Send button with deep-link (wa.me) opening.
/// No backend, Cloud API, or database needed.
class WhatsAppInvoiceButton extends StatelessWidget {
  final String phone;
  final String guestName;
  final String invoiceNumber;
  final double totalAmount;

  const WhatsAppInvoiceButton({
    super.key,
    required this.phone,
    required this.guestName,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          WhatsAppHelper.openWhatsApp(
            context: context,
            rawPhone: phone,
            customerName: guestName,
            invoiceNo: invoiceNumber,
            totalAmount: totalAmount,
          );
        },
        icon: const Icon(Icons.chat, size: 20),
        label: const Text(
          'Send WhatsApp',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }
}

/// A compact inline WhatsApp send chip — for dialogs / cards
class WhatsAppSendChip extends StatelessWidget {
  final String phone;
  final String guestName;
  final String invoiceNumber;
  final double totalAmount;

  const WhatsAppSendChip({
    super.key,
    required this.phone,
    required this.guestName,
    required this.invoiceNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        WhatsAppHelper.openWhatsApp(
          context: context,
          rawPhone: phone,
          customerName: guestName,
          invoiceNo: invoiceNumber,
          totalAmount: totalAmount,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Send WhatsApp (व्हाट्सएप)',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
