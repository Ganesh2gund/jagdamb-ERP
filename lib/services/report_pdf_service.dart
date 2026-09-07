import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfService {
  static Future<Uint8List> generate10DayReportPdf(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    final hotel = (reportData['hotel'] as Map<String, dynamic>?) ?? {};
    final period = (reportData['period'] as Map<String, dynamic>?) ?? {};
    final summary = (reportData['summary'] as Map<String, dynamic>?) ?? {};
    final bookings = (reportData['bookings'] as List<dynamic>?) ?? [];
    final orders = (reportData['orders'] as List<dynamic>?) ?? [];
    final expenses = (reportData['expenses'] as List<dynamic>?) ?? [];

    final hotelName = hotel['name']?.toString() ?? 'Hotel ERP';
    final hotelPhone = hotel['phone']?.toString() ?? '';
    final hotelEmail = hotel['email']?.toString() ?? '';
    final hotelAddress = hotel['address']?.toString() ?? '';

    final cycleNum = period['cycleNumber']?.toString() ?? '1';
    final startDate = period['startDate']?.toString() ?? '';
    final endDate = period['endDate']?.toString() ?? '';

    final roomRev = (summary['roomRevenue'] as num?)?.toDouble() ?? 0.0;
    final restRev = (summary['restaurantRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalRev = (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalExp = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (summary['netProfit'] as num?)?.toDouble() ?? 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ── Hotel Header ──────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 14),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.5)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        hotelName,
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      if (hotelAddress.isNotEmpty) pw.Text(hotelAddress, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      if (hotelPhone.isNotEmpty || hotelEmail.isNotEmpty)
                        pw.Text('Phone: $hotelPhone | Email: $hotelEmail', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text('CYCLE #$cycleNum REPORT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Period: $startDate to $endDate', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────────
            pw.Center(
              child: pw.Text(
                '10-DAY COMPREHENSIVE BILLING & FINANCIAL STATEMENT',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Financial Summary Cards ───────────────────────────
            pw.Row(
              children: [
                _summaryCard('Total Revenue', 'Rs.${totalRev.toStringAsFixed(0)}', PdfColors.blue900, PdfColors.blue50),
                pw.SizedBox(width: 6),
                _summaryCard('Room Rev', 'Rs.${roomRev.toStringAsFixed(0)}', PdfColors.green700, PdfColors.green50),
                pw.SizedBox(width: 6),
                _summaryCard('Restaurant', 'Rs.${restRev.toStringAsFixed(0)}', PdfColors.orange700, PdfColors.orange50),
                pw.SizedBox(width: 6),
                _summaryCard('Expenses', 'Rs.${totalExp.toStringAsFixed(0)}', PdfColors.red700, PdfColors.red50),
                pw.SizedBox(width: 6),
                _summaryCard('Net Profit', 'Rs.${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? PdfColors.blue800 : PdfColors.red800, PdfColors.blue50),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── Section: Room Bookings ────────────────────────────
            pw.Text('1. ROOM BOOKINGS STATEMENT (${bookings.length} Bookings)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            if (bookings.isEmpty)
              pw.Text('No bookings recorded in this cycle.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
            else
              pw.Table.fromTextArray(
                headers: ['Booking #', 'Guest Name', 'Room', 'Dates', 'Total', 'Paid', 'Status'],
                data: bookings.map((b) => [
                  b['bookingNumber']?.toString() ?? '',
                  b['guestName']?.toString() ?? '',
                  b['roomNumber']?.toString() ?? '',
                  '${b['checkInDate']} to ${b['checkOutDate']}',
                  'Rs.${b['totalAmount']}',
                  'Rs.${b['paidAmount']}',
                  b['status']?.toString().toUpperCase() ?? '',
                ]).toList(),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 20,
              ),
            pw.SizedBox(height: 18),

            // ── Section: Restaurant Orders ────────────────────────
            pw.Text('2. RESTAURANT ORDERS STATEMENT (${orders.length} Orders)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            if (orders.isEmpty)
              pw.Text('No restaurant orders recorded in this cycle.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
            else
              pw.Table.fromTextArray(
                headers: ['Order #', 'Type/Target', 'Guest', 'Items Summary', 'Total', 'Payment'],
                data: orders.map((o) => [
                  o['orderNumber']?.toString() ?? '',
                  '${o['type']} (${o['target']})',
                  o['guestName']?.toString() ?? '',
                  o['items']?.toString() ?? '',
                  'Rs.${o['total']}',
                  o['paymentMethod']?.toString() ?? 'Cash',
                ]).toList(),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 20,
              ),
            pw.SizedBox(height: 18),

            // ── Section: Expenses ─────────────────────────────────
            pw.Text('3. HOTEL EXPENSES STATEMENT (${expenses.length} Entries)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 6),
            if (expenses.isEmpty)
              pw.Text('No expenses recorded in this cycle.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
            else
              pw.Table.fromTextArray(
                headers: ['Date', 'Category', 'Description', 'Amount', 'Payment Mode'],
                data: expenses.map((e) => [
                  e['date']?.toString() ?? '',
                  e['category']?.toString() ?? '',
                  e['description']?.toString() ?? '',
                  'Rs.${e['amount']}',
                  e['paymentMethod']?.toString() ?? 'Cash',
                ]).toList(),
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellHeight: 20,
              ),
            pw.SizedBox(height: 24),

            // ── Footer ───────────────────────────────────────────
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by $hotelName ERP System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('All rights reserved | Confidential Hotel Document', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryCard(String title, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  static Future<void> downloadOrPrintReport(Map<String, dynamic> reportData) async {
    final pdfBytes = await generate10DayReportPdf(reportData);
    final period = (reportData['period'] as Map<String, dynamic>?) ?? {};
    final cycleNum = period['cycleNumber']?.toString() ?? '1';
    final fileName = 'Hotel_ERP_10Day_Report_Cycle_$cycleNum.pdf';

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
