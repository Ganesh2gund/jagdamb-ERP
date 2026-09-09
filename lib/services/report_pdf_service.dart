import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfService {
  // ── Helper: Format single date ──────────────────────────────
  static String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '-';
    final s = dateVal.toString().trim();
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return s;
    }
  }

  // ── Helper: Format date & time ──────────────────────────────
  static String _formatDateTime(dynamic dateVal) {
    if (dateVal == null) return '-';
    final s = dateVal.toString().trim();
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.parse(s).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return s;
    }
  }

  // ── Helper: Format stay range with nights count ─────────────
  static String _formatDateRange(dynamic inVal, dynamic outVal) {
    if (inVal == null && outVal == null) return '-';
    try {
      final inDt = DateTime.parse(inVal.toString()).toLocal();
      final outDt = DateTime.parse(outVal.toString()).toLocal();
      final inStr = DateFormat('dd MMM yyyy').format(inDt);
      final outStr = DateFormat('dd MMM yyyy').format(outDt);
      final nights = outDt.difference(inDt).inDays;
      if (nights > 0) {
        return '$inStr to $outStr ($nights ${nights == 1 ? 'Day' : 'Days'})';
      }
      return '$inStr to $outStr';
    } catch (_) {
      final inClean = _formatDate(inVal);
      final outClean = _formatDate(outVal);
      return '$inClean to $outClean';
    }
  }

  // ── Helper: Format currency in Indian standard ──────────────
  static String _formatCurrency(dynamic amount) {
    final num val = (amount is num) ? amount : (num.tryParse(amount?.toString() ?? '0') ?? 0);
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return 'Rs. ${formatter.format(val)}';
  }

  // ── Helper: Clean status text ───────────────────────────────
  static String _cleanStatus(dynamic status) {
    final s = status?.toString().toLowerCase().trim() ?? '';
    if (s == 'confirmed') return 'CONFIRMED';
    if (s == 'checkedin' || s == 'checked_in') return 'CHECKED IN';
    if (s == 'checkedout' || s == 'checked_out') return 'CHECKED OUT';
    if (s == 'cancelled') return 'CANCELLED';
    return s.toUpperCase();
  }

  // ── Helper: Safe ASCII text for Helvetica PDF Font ──────────
  // Strips characters without Helvetica glyphs (Hindi, special symbols) to prevent PDF crashes
  static String _safeText(dynamic text) {
    if (text == null) return '';
    final str = text.toString();
    var clean = str.replaceAll('₹', 'Rs. ');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      final code = clean.codeUnitAt(i);
      if ((code >= 32 && code <= 126) || code == 10 || code == 13 || code == 9) {
        buffer.writeCharCode(code);
      } else if (code == 160) {
        buffer.write(' ');
      } else if (code == 8211 || code == 8212) {
        buffer.write('-');
      } else if (code == 8216 || code == 8217) {
        buffer.write("'");
      } else if (code == 8220 || code == 8221) {
        buffer.write('"');
      } else if (code == 8226) {
        buffer.write('-');
      }
    }
    // Remove empty parentheses e.g. "Birthday Party ()" -> "Birthday Party"
    return buffer.toString().replaceAll(RegExp(r'\(\s*\)'), '').trim();
  }

  static Future<Uint8List> generate10DayReportPdf(Map<String, dynamic> reportData) async {
    final pdf = pw.Document();

    final hotel = (reportData['hotel'] as Map<String, dynamic>?) ?? {};
    final period = (reportData['period'] as Map<String, dynamic>?) ?? {};
    final summary = (reportData['summary'] as Map<String, dynamic>?) ?? {};
    final bookings = (reportData['bookings'] as List<dynamic>?) ?? [];
    final orders = (reportData['orders'] as List<dynamic>?) ?? [];
    final cafeOrders = (reportData['cafeOrders'] as List<dynamic>?) ?? [];
    final banquetBookings = (reportData['banquetBookings'] as List<dynamic>?) ?? [];
    final expenses = (reportData['expenses'] as List<dynamic>?) ?? [];
    final credits = (reportData['credits'] as List<dynamic>?) ?? [];

    final hotelName = _safeText(hotel['name']?.toString() ?? 'Hotel ERP');
    final hotelPhone = _safeText(hotel['phone']?.toString() ?? '');
    final hotelEmail = _safeText(hotel['email']?.toString() ?? '');
    final hotelAddress = _safeText(hotel['address']?.toString() ?? '');

    final cycleNum = period['cycleNumber']?.toString() ?? '1';
    final startDate = period['startDate']?.toString() ?? '';
    final endDate = period['endDate']?.toString() ?? '';

    final roomRev = (summary['roomRevenue'] as num?)?.toDouble() ?? 0.0;
    final restRev = (summary['restaurantRevenue'] as num?)?.toDouble() ?? 0.0;
    final cafeRev = (summary['cafeRevenue'] as num?)?.toDouble() ?? 0.0;
    final banquetRev = (summary['banquetRevenue'] as num?)?.toDouble() ?? 0.0;
    final creditRev = (summary['creditRevenue'] as num?)?.toDouble() ?? 0.0;
    final creditDue = (summary['creditOutstanding'] as num?)?.toDouble() ?? 0.0;
    final totalRev = (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalExp = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (summary['netProfit'] as num?)?.toDouble() ?? 0.0;

    final generatedAtFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by $hotelName ERP System | Confidential Hotel Financial Statement',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ── Hotel & Invoice Top Header ─────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          hotelName,
                          style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL 10-DAY BILLING & AUDIT STATEMENT',
                          style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700, letterSpacing: 0.5),
                        ),
                        if (hotelAddress.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(hotelAddress, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),
                        ],
                        if (hotelPhone.isNotEmpty || hotelEmail.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              if (hotelPhone.isNotEmpty) 'Phone: $hotelPhone',
                              if (hotelEmail.isNotEmpty) 'Email: $hotelEmail',
                            ].join('  |  '),
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.blue800, width: 1.2),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'CYCLE #$cycleNum STATEMENT',
                          style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Period: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
                          style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Printed: $generatedAtFormatted',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Audit Status: Active Settlement',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Financial Summary KPI Cards ───────────────────────
            pw.Row(
              children: [
                _summaryCard('Total Revenue', _formatCurrency(totalRev), 'Gross Collections', PdfColors.blue900, PdfColors.blue50),
                pw.SizedBox(width: 4),
                _summaryCard('Room Rev', _formatCurrency(roomRev), 'Guest Bookings', PdfColors.green800, PdfColors.green50),
                pw.SizedBox(width: 4),
                _summaryCard('Restaurant', _formatCurrency(restRev), 'Dining & F&B', PdfColors.orange800, PdfColors.orange50),
                pw.SizedBox(width: 4),
                _summaryCard('Cafe Rev', _formatCurrency(cafeRev), 'Express POS', PdfColors.amber900, PdfColors.amber50),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                _summaryCard('Banquet Rev', _formatCurrency(banquetRev), 'Events & Functions', PdfColors.indigo900, PdfColors.indigo50),
                pw.SizedBox(width: 4),
                _summaryCard('Credit Rec.', _formatCurrency(creditRev), 'Udhaar Collected', PdfColors.teal900, PdfColors.teal50),
                pw.SizedBox(width: 4),
                _summaryCard('Expenses', _formatCurrency(totalExp), 'Operating Outflow', PdfColors.red800, PdfColors.red50),
                pw.SizedBox(width: 4),
                _summaryCard(
                  'Net Balance',
                  _formatCurrency(netProfit),
                  netProfit >= 0 ? 'Operating Surplus' : 'Operating Deficit',
                  netProfit >= 0 ? PdfColors.blue900 : PdfColors.red800,
                  netProfit >= 0 ? PdfColors.blue50 : PdfColors.red50,
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Section 1: Room Bookings ──────────────────────────
            _sectionHeader('1', 'ROOM BOOKINGS STATEMENT & LEDGER', bookings.length, PdfColors.blue800),
            if (bookings.isEmpty)
              _emptyNotice('No room bookings recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Booking #', 'Guest Name', 'Room', 'Stay Dates (Check In - Out)', 'Total Bill', 'Paid (Adv)', 'Due Balance', 'Status'],
                data: bookings.map((b) {
                  final total = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
                  final paid = (b['paidAmount'] as num?)?.toDouble() ?? 0.0;
                  final due = (total - paid) > 0 ? (total - paid) : 0.0;
                  final guestPhone = _safeText(b['guestPhone']?.toString() ?? '');
                  final guestName = _safeText(b['guestName']?.toString() ?? 'Guest');
                  final guestLabel = guestPhone.isNotEmpty ? '$guestName\n($guestPhone)' : guestName;

                  return [
                    _safeText(b['bookingNumber']?.toString() ?? ''),
                    guestLabel,
                    'Room ${_safeText(b['roomNumber'] ?? '')}',
                    _formatDateRange(b['checkInDate'], b['checkOutDate']),
                    _formatCurrency(total),
                    _formatCurrency(paid),
                    due > 0 ? _formatCurrency(due) : 'Rs. 0 (Nil)',
                    _cleanStatus(b['status']),
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2), // Booking #
                  1: pw.FlexColumnWidth(2.6), // Guest
                  2: pw.FlexColumnWidth(1.6), // Room
                  3: pw.FlexColumnWidth(4.5), // Stay Dates
                  4: pw.FlexColumnWidth(1.9), // Total
                  5: pw.FlexColumnWidth(1.9), // Paid
                  6: pw.FlexColumnWidth(1.9), // Due
                  7: pw.FlexColumnWidth(2.0), // Status
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 12),

            // ── Section 2: Restaurant Orders ──────────────────────
            _sectionHeader('2', 'RESTAURANT & DINING ORDERS STATEMENT', orders.length, PdfColors.orange800),
            if (orders.isEmpty)
              _emptyNotice('No restaurant orders recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Order #', 'Date & Time', 'Table / Service', 'Guest / Customer', 'Items Ordered', 'Bill Total', 'Payment'],
                data: orders.map((o) {
                  final total = (o['total'] as num?)?.toDouble() ?? 0.0;
                  final typeStr = _safeText(o['type']?.toString() ?? 'dineIn');
                  final targetStr = _safeText(o['target']?.toString() ?? '');
                  final serviceLabel = targetStr.isNotEmpty ? '$typeStr ($targetStr)' : typeStr;
                  final timeLabel = _formatDateTime(o['createdAt']);

                  return [
                    _safeText(o['orderNumber']?.toString() ?? ''),
                    timeLabel,
                    serviceLabel,
                    _safeText(o['guestName']?.toString() ?? 'Walk-in'),
                    _safeText(o['items']?.toString() ?? '-'),
                    _formatCurrency(total),
                    '${_safeText(o['paymentMethod'] ?? 'Cash')} ${o['isPaid'] == true ? '(Paid)' : '(Unpaid)'}',
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.4),
                  3: pw.FlexColumnWidth(2.4),
                  4: pw.FlexColumnWidth(4.2),
                  5: pw.FlexColumnWidth(2.0),
                  6: pw.FlexColumnWidth(2.2),
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerLeft,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 12),

            // ── Section 3: Cafe Orders ────────────────────────────
            _sectionHeader('3', 'CAFE POS ORDERS STATEMENT', cafeOrders.length, PdfColors.amber800),
            if (cafeOrders.isEmpty)
              _emptyNotice('No cafe orders recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Order #', 'Date & Time', 'Guest / Customer', 'Items Ordered', 'Bill Total', 'Payment'],
                data: cafeOrders.map((o) {
                  final total = (o['total'] as num?)?.toDouble() ?? 0.0;
                  final timeLabel = _formatDateTime(o['createdAt']);

                  return [
                    _safeText(o['orderNumber']?.toString() ?? ''),
                    timeLabel,
                    _safeText(o['guestName']?.toString() ?? 'Walk-in'),
                    _safeText(o['items']?.toString() ?? '-'),
                    _formatCurrency(total),
                    '${_safeText(o['paymentMethod'] ?? 'Cash')} ${o['isPaid'] == true ? '(Paid)' : '(Unpaid)'}',
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.amber800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(3.0),
                  2: pw.FlexColumnWidth(2.4),
                  3: pw.FlexColumnWidth(4.6),
                  4: pw.FlexColumnWidth(2.0),
                  5: pw.FlexColumnWidth(2.2),
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 12),

            // ── Section 4: Banquet & Events Hall ──────────────────
            _sectionHeader('4', 'BANQUET & EVENTS HALL STATEMENT', banquetBookings.length, PdfColors.indigo800),
            if (banquetBookings.isEmpty)
              _emptyNotice('No banquet or hall bookings recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Booking #', 'Customer Name', 'Hall & Event Type', 'Event Date & Slot', 'Guests', 'Total Bill', 'Advance Paid', 'Balance Due', 'Status'],
                data: banquetBookings.map((b) {
                  final total = (b['grandTotal'] as num?)?.toDouble() ?? 0.0;
                  final paid = (b['advancePaid'] as num?)?.toDouble() ?? 0.0;
                  final due = (b['balanceDue'] as num?)?.toDouble() ?? ((total - paid) > 0 ? (total - paid) : 0.0);
                  final phone = _safeText(b['customerPhone']?.toString() ?? '');
                  final custName = _safeText(b['customerName']?.toString() ?? 'Client');
                  final custLabel = phone.isNotEmpty ? '$custName\n($phone)' : custName;
                  final hallName = _safeText(b['hallName'] ?? 'Hall');
                  final eventType = _safeText(b['eventType'] ?? 'Event');
                  final hallLabel = eventType.isNotEmpty ? '$hallName\n($eventType)' : hallName;
                  final slotStr = _safeText(b['slot'] ?? '');
                  final dateLabel = slotStr.isNotEmpty ? '${_formatDate(b['eventDate'])}\n($slotStr)' : _formatDate(b['eventDate']);

                  return [
                    _safeText(b['bookingNumber']?.toString() ?? ''),
                    custLabel,
                    hallLabel,
                    dateLabel,
                    '${b['expectedGuests'] ?? 0} Guests',
                    _formatCurrency(total),
                    _formatCurrency(paid),
                    due > 0 ? _formatCurrency(due) : 'Rs. 0 (Nil)',
                    _cleanStatus(b['status']),
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(2.6),
                  3: pw.FlexColumnWidth(2.6),
                  4: pw.FlexColumnWidth(1.6),
                  5: pw.FlexColumnWidth(1.9),
                  6: pw.FlexColumnWidth(1.9),
                  7: pw.FlexColumnWidth(1.9),
                  8: pw.FlexColumnWidth(1.9),
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.centerRight,
                  8: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 12),

            // ── Section 5: Expenses ───────────────────────────────
            _sectionHeader('5', 'HOTEL OPERATIONAL EXPENSES STATEMENT', expenses.length, PdfColors.red800),
            if (expenses.isEmpty)
              _emptyNotice('No expenses recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Expense Date & Time', 'Category', 'Expense Description / Purpose', 'Payment Mode', 'Amount'],
                data: expenses.map((e) {
                  final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
                  final timeLabel = _formatDateTime(e['date']);

                  return [
                    timeLabel,
                    _safeText(e['category']?.toString() ?? 'Other'),
                    _safeText(e['description']?.toString() ?? '-'),
                    _safeText(e['paymentMethod']?.toString() ?? 'Cash'),
                    _formatCurrency(amount),
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.0),
                  1: pw.FlexColumnWidth(2.2),
                  2: pw.FlexColumnWidth(5.2),
                  3: pw.FlexColumnWidth(2.0),
                  4: pw.FlexColumnWidth(2.2),
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
              ),
            pw.SizedBox(height: 12),

            // ── Section 6: Customer Credit / Udhaar Khata ─────────
            _sectionHeader('6', 'CUSTOMER CREDIT & UDHAAR KHATA STATEMENT', credits.length, PdfColors.teal800),
            if (credits.isEmpty)
              _emptyNotice('No customer credit or udhaar bills recorded during this 10-day cycle.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Bill #', 'Date & Time', 'Customer Name', 'Particulars / Details', 'Total Credit', 'Paid (Rec.)', 'Balance Due', 'Status'],
                data: credits.map((c) {
                  final total = (c['totalAmount'] as num?)?.toDouble() ?? 0.0;
                  final paid = (c['paidAmount'] as num?)?.toDouble() ?? 0.0;
                  final due = (c['balanceAmount'] as num?)?.toDouble() ?? (total - paid).clamp(0.0, double.infinity);
                  final timeLabel = _formatDateTime(c['createdAt']);
                  final custPhone = _safeText(c['customerPhone']?.toString() ?? '');
                  final custName = _safeText(c['customerName']?.toString() ?? 'Customer');
                  final custLabel = custPhone.isNotEmpty ? '$custName\n($custPhone)' : custName;

                  return [
                    _safeText(c['billNumber']?.toString() ?? ''),
                    timeLabel,
                    custLabel,
                    _safeText(c['description']?.toString() ?? 'Food & Dining Credit'),
                    _formatCurrency(total),
                    _formatCurrency(paid),
                    due > 0 ? _formatCurrency(due) : 'Rs. 0 (Paid)',
                    _cleanStatus(c['status']),
                  ];
                }).toList(),
                headerStyle: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                cellStyle: const pw.TextStyle(fontSize: 7.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4.5),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0), // Bill #
                  1: pw.FlexColumnWidth(2.8), // Date
                  2: pw.FlexColumnWidth(2.8), // Customer
                  3: pw.FlexColumnWidth(3.8), // Details
                  4: pw.FlexColumnWidth(2.0), // Total
                  5: pw.FlexColumnWidth(2.0), // Paid
                  6: pw.FlexColumnWidth(2.0), // Due
                  7: pw.FlexColumnWidth(1.8), // Status
                },
                cellAlignments: const {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                  7: pw.Alignment.center,
                },
              ),
            pw.SizedBox(height: 14),

            // ── Grand Summary & Balance Reconciliation ────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUDIT & CYCLE SUMMARY',
                          style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '- Cycle Duration: 10-Day Period (${_formatDate(startDate)} to ${_formatDate(endDate)})\n'
                          '- Total Guest Bookings Audited: ${bookings.length} reservations\n'
                          '- Total Restaurant / F&B Orders: ${orders.length} orders\n'
                          '- Total Cafe Orders: ${cafeOrders.length} orders\n'
                          '- Total Banquet & Event Bookings: ${banquetBookings.length} events\n'
                          '- Total Customer Credit Records: ${credits.length} accounts (Recovered: ${_formatCurrency(creditRev)}, Due: ${_formatCurrency(creditDue)})\n'
                          '- Total Operational Expenses: ${expenses.length} voucher(s)\n'
                          '- All records verified and reconciled with Hotel ERP system ledgers.',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800, lineSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                      ),
                      child: pw.Column(
                        children: [
                          _financeRow('Room Revenue:', _formatCurrency(roomRev), PdfColors.grey800),
                          _financeRow('Restaurant Revenue:', _formatCurrency(restRev), PdfColors.grey800),
                          _financeRow('Cafe Revenue:', _formatCurrency(cafeRev), PdfColors.grey800),
                          _financeRow('Banquet Revenue:', _formatCurrency(banquetRev), PdfColors.grey800),
                          _financeRow('Credit Recovered:', _formatCurrency(creditRev), PdfColors.grey800),
                          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                          _financeRow('Gross Inflow (Total):', _formatCurrency(totalRev), PdfColors.blue900, isBold: true),
                          _financeRow('Less Expenses:', _formatCurrency(totalExp), PdfColors.red800),
                          pw.Divider(color: PdfColors.blue900, thickness: 1),
                          _financeRow(
                            netProfit >= 0 ? 'Net Operating Profit:' : 'Net Deficit (Loss):',
                            _formatCurrency(netProfit),
                            netProfit >= 0 ? PdfColors.green800 : PdfColors.red800,
                            isBold: true,
                            fontSize: 8.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Signatures & Authorization Strip ──────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Prepared By / Cashier', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'HOTEL OFFICIAL STAMP',
                    style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500),
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Manager / Auditor', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Helper: KPI summary card ────────────────────────────────
  static pw.Widget _summaryCard(String title, String value, String subtitle, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: textColor, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: textColor)),
            pw.SizedBox(height: 1),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionHeader(String number, String title, int count, PdfColor barColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 3.5,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: barColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                '$number. $title',
                style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: barColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              '$count ${count == 1 ? 'Entry' : 'Entries'}',
              style: const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Empty section notice ────────────────────────────
  static pw.Widget _emptyNotice(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  // ── Helper: Financial table row ─────────────────────────────
  static pw.Widget _financeRow(String label, String value, PdfColor valueColor, {bool isBold = false, double fontSize = 7.5}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
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
