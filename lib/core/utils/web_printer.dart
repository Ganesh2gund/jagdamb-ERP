import 'platform_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../services/api_client.dart';

class WebPrinter {
  // Global synchronized hotel branding details
  static String hotelName = AppConstants.hotelName;
  static String hotelAddress = 'Near Central Station, Luxury Suites & Rooms';
  static String hotelPhone = '';
  static String hotelEmail = '';

  /// Initialize hotel branding from local cache and server
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('hotel_name');
      final a = prefs.getString('hotel_address');
      final p = prefs.getString('hotel_phone');
      final e = prefs.getString('hotel_email');
      if (n != null && n.trim().isNotEmpty) hotelName = n.trim();
      if (a != null && a.trim().isNotEmpty) hotelAddress = a.trim();
      if (p != null) hotelPhone = p.trim();
      if (e != null) hotelEmail = e.trim();
    } catch (_) {}

    try {
      final res = await ApiClient.instance.get('/settings');
      final s = res['settings'] as Map<String, dynamic>? ?? {};
      if (s['hotelName'] != null && (s['hotelName'] as String).trim().isNotEmpty) {
        hotelName = (s['hotelName'] as String).trim();
      }
      if (s['hotelAddress'] != null && (s['hotelAddress'] as String).trim().isNotEmpty) {
        hotelAddress = (s['hotelAddress'] as String).trim();
      }
      if (s['hotelPhone'] != null) hotelPhone = (s['hotelPhone'] as String).trim();
      if (s['hotelEmail'] != null) hotelEmail = (s['hotelEmail'] as String).trim();
    } catch (_) {}
  }

  /// Update cached config immediately when user updates settings
  static void updateConfig({
    String? name,
    String? address,
    String? phone,
    String? email,
  }) {
    if (name != null && name.trim().isNotEmpty) hotelName = name.trim();
    if (address != null && address.trim().isNotEmpty) hotelAddress = address.trim();
    if (phone != null) hotelPhone = phone.trim();
    if (email != null) hotelEmail = email.trim();
  }

  static void printInvoice({
    required String invoiceNumber,
    required String guestName,
    required String guestPhone,
    required String roomNumber,
    required String roomType,
    required String checkIn,
    required String checkOut,
    required int nights,
    required double roomCharge,
    required double totalAmount,
    required double paidAmount,
    double advanceAmount = 0.0,
    String? hotelName,
    String? hotelAddress,
    String? hotelPhone,
    String? hotelEmail,
  }) {
    final effectiveHotelName = (hotelName != null && hotelName.trim().isNotEmpty)
        ? hotelName.trim()
        : (WebPrinter.hotelName.trim().isNotEmpty ? WebPrinter.hotelName.trim() : AppConstants.hotelName);

    final effectiveHotelAddress = (hotelAddress != null && hotelAddress.trim().isNotEmpty)
        ? hotelAddress.trim()
        : WebPrinter.hotelAddress.trim();

    final effectiveHotelPhone = (hotelPhone != null && hotelPhone.trim().isNotEmpty)
        ? hotelPhone.trim()
        : WebPrinter.hotelPhone.trim();

    final effectiveHotelEmail = (hotelEmail != null && hotelEmail.trim().isNotEmpty)
        ? hotelEmail.trim()
        : WebPrinter.hotelEmail.trim();

    final nowStr = DateTime.now().toString().split('.')[0];
    final balanceCollectedAtCheckout = (totalAmount - advanceAmount).clamp(0.0, double.infinity);
    final balanceDue = (totalAmount - paidAmount).clamp(0.0, double.infinity);

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Receipt - $invoiceNumber</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #f8fafc;
      margin: 0;
      padding: 24px;
      color: #0f172a;
    }
    .invoice-card {
      max-width: 650px;
      margin: 0 auto;
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 12px;
      padding: 32px;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.08);
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #e2e8f0;
      padding-bottom: 20px;
      margin-bottom: 20px;
      gap: 16px;
    }
    .brand-title {
      font-size: 24px;
      font-weight: 900;
      color: #4f46e5;
      margin: 0 0 4px 0;
      letter-spacing: -0.5px;
    }
    .brand-sub {
      font-size: 13px;
      color: #64748b;
      margin: 2px 0;
    }
    .brand-contact {
      font-size: 12px;
      color: #475569;
      margin-top: 4px;
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
    }
    .invoice-meta {
      text-align: right;
      flex-shrink: 0;
    }
    .invoice-tag {
      display: inline-block;
      background: #e0e7ff;
      color: #4338ca;
      font-size: 13px;
      font-weight: 800;
      padding: 4px 10px;
      border-radius: 6px;
      letter-spacing: 0.5px;
      margin-bottom: 6px;
    }
    .invoice-number {
      font-size: 14px;
      font-weight: 700;
      color: #1e293b;
      margin: 0;
    }
    .invoice-date {
      font-size: 12px;
      color: #64748b;
      margin: 2px 0 0 0;
    }
    .details-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 24px;
      gap: 20px;
    }
    .details-box {
      flex: 1;
      background: #f8fafc;
      border: 1px solid #f1f5f9;
      border-radius: 8px;
      padding: 12px 16px;
    }
    .details-title {
      font-size: 11px;
      text-transform: uppercase;
      font-weight: 700;
      color: #94a3b8;
      letter-spacing: 0.5px;
      margin-bottom: 6px;
    }
    .details-text {
      font-size: 14px;
      font-weight: 700;
      color: #1e293b;
      margin: 0;
    }
    .details-sub {
      font-size: 12px;
      color: #64748b;
      margin: 4px 0 0 0;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 24px;
    }
    th {
      background: #f1f5f9;
      color: #475569;
      text-align: left;
      padding: 10px 14px;
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    td {
      padding: 14px;
      border-bottom: 1px solid #f1f5f9;
      font-size: 13px;
    }
    .calculation-box {
      margin-left: auto;
      width: 320px;
      background: #f8fafc;
      border-radius: 8px;
      padding: 16px;
      border: 1px solid #f1f5f9;
    }
    .calc-row {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      margin-bottom: 8px;
      color: #475569;
    }
    .calc-row.total {
      font-size: 16px;
      font-weight: 800;
      color: #0f172a;
      border-top: 2px solid #e2e8f0;
      padding-top: 10px;
      margin-top: 10px;
    }
    .calc-row.advance {
      color: #059669;
      font-weight: 700;
    }
    .calc-row.paid {
      color: #2563eb;
      font-weight: 700;
    }
    .status-badge {
      display: inline-block;
      margin-top: 20px;
      padding: 8px 16px;
      background: #ecfdf5;
      color: #059669;
      border: 1px solid #a7f3d0;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 800;
      letter-spacing: 0.5px;
    }
    .footer-note {
      margin-top: 32px;
      padding-top: 16px;
      border-top: 1px solid #f1f5f9;
      text-align: center;
      font-size: 12px;
      color: #94a3b8;
      line-height: 1.6;
    }
    .print-btn-bar {
      max-width: 650px;
      margin: 0 auto 16px auto;
      display: flex;
      justify-content: flex-end;
    }
    .print-button {
      background: #4f46e5;
      color: #ffffff;
      border: none;
      padding: 10px 20px;
      border-radius: 8px;
      font-weight: 700;
      font-size: 14px;
      cursor: pointer;
      box-shadow: 0 2px 4px rgba(79,70,229,0.2);
    }
    .print-button:hover {
      background: #4338ca;
    }
    @media print {
      body {
        background: #ffffff;
        padding: 0;
      }
      .invoice-card {
        border: none;
        box-shadow: none;
        padding: 0;
        max-width: 100%;
      }
      .print-btn-bar {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="print-btn-bar">
    <button class="print-button" onclick="window.print()">🖨️ Print Invoice / Save as PDF</button>
  </div>

  <div class="invoice-card">
    <div class="header">
      <div style="flex: 1;">
        <h1 class="brand-title">$effectiveHotelName</h1>
        ${effectiveHotelAddress.isNotEmpty ? '<p class="brand-sub">📍 $effectiveHotelAddress</p>' : ''}
        ${(effectiveHotelPhone.isNotEmpty || effectiveHotelEmail.isNotEmpty) ? '''
        <div class="brand-contact">
          ${effectiveHotelPhone.isNotEmpty ? '<span>📞 <strong>Mob:</strong> $effectiveHotelPhone</span>' : ''}
          ${effectiveHotelEmail.isNotEmpty ? '<span>✉️ <strong>Email:</strong> $effectiveHotelEmail</span>' : ''}
        </div>
        ''' : ''}
      </div>
      <div class="invoice-meta">
        <div class="invoice-tag">HOTEL RECEIPT / INVOICE</div>
        <p class="invoice-number">#$invoiceNumber</p>
        <p class="invoice-date">Date: $nowStr</p>
      </div>
    </div>

    <div class="details-row">
      <div class="details-box">
        <div class="details-title">Billed To (Guest)</div>
        <p class="details-text">$guestName</p>
        <p class="details-sub">Phone: $guestPhone</p>
      </div>
      <div class="details-box">
        <div class="details-title">Stay Details</div>
        <p class="details-text">Room $roomNumber ($roomType)</p>
        <p class="details-sub">$checkIn - $checkOut ($nights Night(s))</p>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>Item / Service</th>
          <th style="text-align: center;">Nights</th>
          <th style="text-align: right;">Amount</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Room $roomNumber ($roomType) Stay</strong><br><span style="font-size: 11px; color: #64748b;">$nights night(s) stay charges</span></td>
          <td style="text-align: center;">$nights</td>
          <td style="text-align: right;"><strong>₹${roomCharge.toStringAsFixed(2)}</strong></td>
        </tr>
      </tbody>
    </table>

    <div class="calculation-box">
      <div class="calc-row">
        <span>Room Charge:</span>
        <span>₹${roomCharge.toStringAsFixed(2)}</span>
      </div>
      
      <div class="calc-row total">
        <span>Total Bill (कुल बिल):</span>
        <span>₹${totalAmount.toStringAsFixed(2)}</span>
      </div>

      ${advanceAmount > 0 ? '''
      <div class="calc-row advance" style="margin-top: 8px;">
        <span>Advance Paid (अग्रिम जमा):</span>
        <span>- ₹${advanceAmount.toStringAsFixed(2)}</span>
      </div>
      ''' : ''}

      ${advanceAmount > 0 && balanceCollectedAtCheckout > 0 ? '''
      <div class="calc-row paid">
        <span>Paid at Checkout (चेकआउट भुगतान):</span>
        <span>₹${balanceCollectedAtCheckout.toStringAsFixed(2)}</span>
      </div>
      ''' : ''}
      
      <div class="calc-row" style="font-weight: 700; color: #0f172a; border-top: 1px solid #e2e8f0; padding-top: 6px; margin-top: 6px;">
        <span>Total Paid (कुल प्राप्त):</span>
        <span>₹${paidAmount.toStringAsFixed(2)}</span>
      </div>

      <div class="calc-row" style="color: ${balanceDue > 0 ? '#dc2626' : '#64748b'}; font-size: 12px; font-weight: ${balanceDue > 0 ? '700' : '400'};">
        <span>Balance Due (बकाया):</span>
        <span>₹${balanceDue.toStringAsFixed(2)}</span>
      </div>
    </div>

    <div class="status-badge" style="background: ${balanceDue <= 0 ? '#ecfdf5' : '#fffbeb'}; color: ${balanceDue <= 0 ? '#059669' : '#b45309'}; border-color: ${balanceDue <= 0 ? '#a7f3d0' : '#fde68a'};">
      ${balanceDue <= 0 ? '✓ PAYMENT RECEIVED IN FULL • BILL SETTLED' : 'PARTIAL PAYMENT • ADVANCE RECORDED'}
    </div>

    <div class="footer-note">
      Thank you for staying at $effectiveHotelName! We look forward to hosting you again.<br>
      ${effectiveHotelPhone.isNotEmpty ? 'For assistance or inquiries, Call/WhatsApp: $effectiveHotelPhone<br>' : ''}
      This is a computer generated invoice and requires no physical signature.
    </div>
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 400);
    };
  </script>
</body>
</html>
''';

    openHtmlContent(htmlContent);
  }

  static void printRestaurantReceipt({
    required String orderId,
    required String tableOrCounter,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    String? guestName,
    String? hotelName,
    String? hotelAddress,
    String? hotelPhone,
  }) {
    final effectiveHotelName = (hotelName != null && hotelName.trim().isNotEmpty)
        ? hotelName.trim()
        : (WebPrinter.hotelName.trim().isNotEmpty ? WebPrinter.hotelName.trim() : AppConstants.hotelName);

    final effectiveHotelAddress = (hotelAddress != null && hotelAddress.trim().isNotEmpty)
        ? hotelAddress.trim()
        : WebPrinter.hotelAddress.trim();

    final effectiveHotelPhone = (hotelPhone != null && hotelPhone.trim().isNotEmpty)
        ? hotelPhone.trim()
        : WebPrinter.hotelPhone.trim();

    final nowStr = DateTime.now().toString().split('.')[0];
    final itemsHtml = items.map((i) {
      final name = i['name'] ?? '';
      final qty = i['quantity'] ?? 1;
      final price = (i['price'] as num?)?.toDouble() ?? 0.0;
      final total = (price * qty).toStringAsFixed(2);
      return '''
        <tr>
          <td><strong>$name</strong></td>
          <td style="text-align:center;">$qty</td>
          <td style="text-align:right;">₹${price.toStringAsFixed(2)}</td>
          <td style="text-align:right;"><strong>₹$total</strong></td>
        </tr>
      ''';
    }).join('');

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Receipt - $orderId</title>
  <style>
    body { font-family: 'Courier New', Courier, monospace, sans-serif; background: #f1f5f9; padding: 20px; color: #1e293b; }
    .slip { max-width: 380px; margin: 0 auto; background: #fff; border: 1px dashed #94a3b8; border-radius: 8px; padding: 24px; }
    .center { text-align: center; }
    h2 { margin: 0 0 4px 0; font-size: 20px; font-weight: 800; }
    p { margin: 2px 0; font-size: 13px; color: #475569; }
    .divider { border-top: 1px dashed #cbd5e1; margin: 12px 0; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; margin: 10px 0; }
    th { text-align: left; border-bottom: 1px dashed #cbd5e1; padding-bottom: 6px; }
    td { padding: 4px 0; }
    .total-row { font-size: 16px; font-weight: 800; border-top: 2px solid #0f172a; padding-top: 8px; margin-top: 8px; }
    .paid-tag { background: #dcfce7; color: #166534; font-weight: 700; padding: 6px; border-radius: 6px; text-align: center; margin-top: 12px; }
    @media print {
      body { background: #fff; padding: 0; }
      .slip { border: none; max-width: 100%; padding: 0; }
      .print-btn { display: none; }
    }
  </style>
</head>
<body>
  <div style="text-align: center; margin-bottom: 16px;" class="print-btn">
    <button style="padding: 8px 16px; background: #4f46e5; color: #fff; border: none; border-radius: 6px; font-weight: 700; cursor: pointer;" onclick="window.print()">🖨️ Print Bill Receipt</button>
  </div>
  <div class="slip">
    <div class="center">
      <h2>$effectiveHotelName</h2>
      <p>Restaurant Food & Dining Bill</p>
      ${effectiveHotelAddress.isNotEmpty ? '<p style="font-size: 11px;">📍 $effectiveHotelAddress</p>' : ''}
      ${effectiveHotelPhone.isNotEmpty ? '<p style="font-size: 11px;">📞 $effectiveHotelPhone</p>' : ''}
      <p style="font-size: 12px; margin-top: 4px;">Bill No: #$orderId | $nowStr</p>
    </div>
    <div class="divider"></div>
    <p><strong>Type / Target:</strong> $tableOrCounter</p>
    ${guestName != null && guestName.isNotEmpty ? '<p><strong>Guest:</strong> $guestName</p>' : ''}
    <p><strong>Payment Mode:</strong> $paymentMethod (Paid)</p>
    <div class="divider"></div>
    <table>
      <thead>
        <tr>
          <th>Item</th>
          <th style="text-align:center;">Qty</th>
          <th style="text-align:right;">Rate</th>
          <th style="text-align:right;">Amt</th>
        </tr>
      </thead>
      <tbody>
        $itemsHtml
      </tbody>
    </table>
    <div class="divider"></div>
    <div style="display:flex; justify-content:space-between;" class="total-row">
      <span>Grand Total (कुल):</span>
      <span>₹${totalAmount.toStringAsFixed(2)}</span>
    </div>
    <div class="paid-tag">
      ✓ PAYMENT RECEIVED VIA $paymentMethod
    </div>
    <div class="center" style="margin-top: 16px; font-size: 12px; color: #64748b;">
      Thank you for dining with us at $effectiveHotelName!
    </div>
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() { window.print(); }, 400);
    };
  </script>
</body>
</html>
''';

    openHtmlContent(htmlContent);
  }

  static void printCafeReceipt({
    required String orderNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String paymentMethod,
    String? guestName,
    String? hotelName,
    String? hotelAddress,
    String? hotelPhone,
  }) {
    final effectiveHotelName = (hotelName != null && hotelName.trim().isNotEmpty)
        ? hotelName.trim()
        : (WebPrinter.hotelName.trim().isNotEmpty ? WebPrinter.hotelName.trim() : AppConstants.hotelName);

    final effectiveHotelAddress = (hotelAddress != null && hotelAddress.trim().isNotEmpty)
        ? hotelAddress.trim()
        : WebPrinter.hotelAddress.trim();

    final effectiveHotelPhone = (hotelPhone != null && hotelPhone.trim().isNotEmpty)
        ? hotelPhone.trim()
        : WebPrinter.hotelPhone.trim();

    final nowStr = DateTime.now().toString().split('.')[0];
    final itemsHtml = items.map((i) {
      final name = i['name'] ?? '';
      final qty = i['quantity'] ?? 1;
      final price = (i['price'] as num?)?.toDouble() ?? 0.0;
      final total = (price * qty).toStringAsFixed(2);
      return '''
        <tr>
          <td><strong>$name</strong></td>
          <td style="text-align:center;">$qty</td>
          <td style="text-align:right;">₹${price.toStringAsFixed(2)}</td>
          <td style="text-align:right;"><strong>₹$total</strong></td>
        </tr>
      ''';
    }).join('');

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Cafe Bill - $orderNumber</title>
  <style>
    body { font-family: 'Courier New', Courier, monospace, sans-serif; background: #fdfbf7; padding: 20px; color: #1e293b; }
    .slip { max-width: 380px; margin: 0 auto; background: #fff; border: 1px dashed #d97706; border-radius: 8px; padding: 24px; }
    .center { text-align: center; }
    h2 { margin: 0 0 4px 0; font-size: 20px; font-weight: 800; color: #78350f; }
    p { margin: 2px 0; font-size: 13px; color: #475569; }
    .divider { border-top: 1px dashed #fcd34d; margin: 12px 0; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; margin: 10px 0; }
    th { text-align: left; border-bottom: 1px dashed #fcd34d; padding-bottom: 6px; }
    td { padding: 4px 0; }
    .total-row { font-size: 16px; font-weight: 800; border-top: 2px solid #b45309; padding-top: 8px; margin-top: 8px; }
    .paid-tag { background: #fef3c7; color: #92400e; font-weight: 700; padding: 6px; border-radius: 6px; text-align: center; margin-top: 12px; border: 1px solid #fde68a; }
    @media print {
      body { background: #fff; padding: 0; }
      .slip { border: none; max-width: 100%; padding: 0; }
      .print-btn { display: none; }
    }
  </style>
</head>
<body>
  <div style="text-align: center; margin-bottom: 16px;" class="print-btn">
    <button style="padding: 8px 16px; background: #d97706; color: #fff; border: none; border-radius: 6px; font-weight: 700; cursor: pointer;" onclick="window.print()">🖨️ Print Cafe Bill</button>
  </div>
  <div class="slip">
    <div class="center">
      <h2>☕ $effectiveHotelName CAFE</h2>
      <p>Coffee, Beverages & Snacks</p>
      ${effectiveHotelAddress.isNotEmpty ? '<p style="font-size: 11px;">📍 $effectiveHotelAddress</p>' : ''}
      ${effectiveHotelPhone.isNotEmpty ? '<p style="font-size: 11px;">📞 $effectiveHotelPhone</p>' : ''}
      <p style="font-size: 12px; margin-top: 4px;">Bill No: <strong>#$orderNumber</strong> | $nowStr</p>
    </div>
    <div class="divider"></div>
    <p><strong>Counter Sale:</strong> Express POS</p>
    ${guestName != null && guestName.isNotEmpty ? '<p><strong>Customer:</strong> $guestName</p>' : ''}
    <p><strong>Payment:</strong> $paymentMethod (Paid)</p>
    <div class="divider"></div>
    <table>
      <thead>
        <tr>
          <th>Item</th>
          <th style="text-align:center;">Qty</th>
          <th style="text-align:right;">Rate</th>
          <th style="text-align:right;">Amt</th>
        </tr>
      </thead>
      <tbody>
        $itemsHtml
      </tbody>
    </table>
    <div class="divider"></div>
    <div style="display:flex; justify-content:space-between;" class="total-row">
      <span>Grand Total (कुल):</span>
      <span>₹${totalAmount.toStringAsFixed(2)}</span>
    </div>
    <div class="paid-tag">
      ✓ PAYMENT RECEIVED VIA $paymentMethod
    </div>
    <div class="center" style="margin-top: 16px; font-size: 12px; color: #78350f;">
      Thank you! Visit again for freshly brewed coffee ☕
    </div>
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() { window.print(); }, 400);
    };
  </script>
</body>
</html>
''';

    openHtmlContent(htmlContent);
  }
}
