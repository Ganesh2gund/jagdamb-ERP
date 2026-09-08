import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/web_printer.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_client.dart';
import '../../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Hotel Profile controllers
  final _hotelNameCtrl = TextEditingController();
  final _hotelPhoneCtrl = TextEditingController();
  final _hotelEmailCtrl = TextEditingController();
  final _hotelAddressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hotelNameCtrl.dispose();
    _hotelPhoneCtrl.dispose();
    _hotelEmailCtrl.dispose();
    _hotelAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('hotel_name');
      final localPhone = prefs.getString('hotel_phone');
      final localEmail = prefs.getString('hotel_email');
      final localAddress = prefs.getString('hotel_address');
      if (localName != null && localName.isNotEmpty && mounted) {
        _hotelNameCtrl.text = localName;
      }
      if (localPhone != null && mounted) _hotelPhoneCtrl.text = localPhone;
      if (localEmail != null && mounted) _hotelEmailCtrl.text = localEmail;
      if (localAddress != null && mounted) _hotelAddressCtrl.text = localAddress;
    } catch (_) {}

    try {
      final data = await ApiClient.instance.get('/settings');
      if (!mounted) return;
      final s = data['settings'] as Map<String, dynamic>? ?? {};
      setState(() {
        if (s['hotelName'] != null && (s['hotelName'] as String).trim().isNotEmpty) {
          _hotelNameCtrl.text = s['hotelName'];
        }
        if (s['hotelPhone'] != null) _hotelPhoneCtrl.text = s['hotelPhone'];
        if (s['hotelEmail'] != null) _hotelEmailCtrl.text = s['hotelEmail'];
        if (s['hotelAddress'] != null) _hotelAddressCtrl.text = s['hotelAddress'];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final hotelName = _hotelNameCtrl.text.trim();
    final hotelPhone = _hotelPhoneCtrl.text.trim();
    final hotelEmail = _hotelEmailCtrl.text.trim();
    final hotelAddress = _hotelAddressCtrl.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hotel_name', hotelName);
      await prefs.setString('hotel_phone', hotelPhone);
      await prefs.setString('hotel_email', hotelEmail);
      await prefs.setString('hotel_address', hotelAddress);

      WebPrinter.updateConfig(
        name: hotelName,
        phone: hotelPhone,
        email: hotelEmail,
        address: hotelAddress,
      );
    } catch (_) {}

    try {
      final body = <String, dynamic>{
        'hotelName': hotelName,
        'hotelPhone': hotelPhone,
        'hotelEmail': hotelEmail,
        'hotelAddress': hotelAddress,
      };

      await ApiClient.instance.put('/settings', body: body);
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Settings saved successfully!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState(message: 'Loading settings...'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotel Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hotel Profile ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.hotel,
            title: 'Hotel Profile',
            subtitle: 'These details will appear on invoices and receipts',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _hotelNameCtrl,
            label: 'Hotel Name',
            icon: Icons.hotel,
            hint: 'e.g. Hotel Grand Palace',
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _hotelAddressCtrl,
            label: 'Address',
            icon: Icons.location_on,
            hint: 'Enter hotel address',
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _hotelPhoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone,
            hint: '+91 98765 43210',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _hotelEmailCtrl,
            label: 'Email',
            icon: Icons.email,
            hint: 'hotel@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // ── WhatsApp Info ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'WhatsApp: Billing screen par "Send WhatsApp" button se directly customer ko invoice bhej sakte ho. Koi setup nahi chahiye!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Backend Status ─────────────────────────────────────
          _SectionHeader(
            icon: Icons.cloud,
            title: 'Backend Status',
            subtitle: 'Server connection status',
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: ApiClient.instance.checkHealth(),
            builder: (context, snapshot) {
              final isLive = snapshot.data == true;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: isLive ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isLive ? 'Fastify Server — Connected 🟢' : 'Server connecting... 🟡',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Save Button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Settings',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
              label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    ConfirmDialog.show(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      confirmColor: AppColors.error,
      onConfirm: () async {
        final authService = context.read<AuthService>();
        await authService.logout();
        if (!context.mounted) return;
        context.go('/login');
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (badgeColor ?? AppColors.primary).withOpacity(0.4)),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
