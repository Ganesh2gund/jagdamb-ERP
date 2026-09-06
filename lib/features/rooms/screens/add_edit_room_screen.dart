import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room.dart';
import '../../../services/api_client.dart';

class AddEditRoomScreen extends StatefulWidget {
  final Room? existingRoom; // null = Add mode, non-null = Edit mode

  const AddEditRoomScreen({super.key, this.existingRoom});

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _numberCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _maxGuestsCtrl;
  late final TextEditingController _amenitiesCtrl;

  RoomType _selectedType = RoomType.standard;

  bool get _isEditMode => widget.existingRoom != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRoom;
    _numberCtrl = TextEditingController(text: r?.number ?? '');
    _floorCtrl = TextEditingController(text: r?.floor.toString() ?? '1');
    _priceCtrl = TextEditingController(text: r?.pricePerNight.toStringAsFixed(0) ?? '');
    _maxGuestsCtrl = TextEditingController(text: r?.maxGuests.toString() ?? '2');
    _amenitiesCtrl = TextEditingController(text: r?.amenities.join(', ') ?? '');
    if (r != null) _selectedType = r.type;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _floorCtrl.dispose();
    _priceCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _amenitiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amenities = _amenitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      if (_isEditMode) {
        // Edit mode: call PUT /api/rooms/:id
        await ApiClient.instance.put('/rooms/${widget.existingRoom!.id}', body: {
          'number': _numberCtrl.text.trim(),
          'floor': int.parse(_floorCtrl.text.trim()),
          'type': _selectedType.name,
          'pricePerNight': double.parse(_priceCtrl.text.trim()),
          'amenities': amenities,
          'maxGuests': int.parse(_maxGuestsCtrl.text.trim()),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Room ${_numberCtrl.text} updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.available,
            ),
          );
          context.pop(true); // pop with refresh signal
        }
      } else {
        // Add mode: call POST /api/rooms
        await ApiClient.instance.post('/rooms', body: {
          'number': _numberCtrl.text.trim(),
          'floor': int.parse(_floorCtrl.text.trim()),
          'type': _selectedType.name,
          'pricePerNight': double.parse(_priceCtrl.text.trim()),
          'amenities': amenities,
          'maxGuests': int.parse(_maxGuestsCtrl.text.trim()),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Room ${_numberCtrl.text} added successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.available,
            ),
          );
          context.pop(true); // pop with refresh signal
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('ApiException: ', '')}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/rooms');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Room ${widget.existingRoom!.number}' : 'Add New Room'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back to Rooms)',
            onPressed: () => context.go('/rooms'),
          ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _isEditMode ? 'Update' : 'Add Room',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Room Identity Section
            _SectionCard(
              title: 'Room Identity',
              icon: Icons.hotel,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numberCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Room Number *',
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'e.g. 101',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _floorCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Floor *',
                          prefixIcon: Icon(Icons.stairs),
                          hintText: 'e.g. 1',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Room Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: RoomType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  )).toList(),
                  onChanged: (t) => setState(() => _selectedType = t ?? RoomType.standard),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pricing & Capacity Section
            _SectionCard(
              title: 'Pricing & Capacity',
              icon: Icons.monetization_on,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price per Night (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee),
                          hintText: 'e.g. 3500',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxGuestsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Guests *',
                          prefixIcon: Icon(Icons.people),
                          hintText: 'e.g. 2',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amenities Section
            _SectionCard(
              title: 'Amenities',
              icon: Icons.star_border,
              children: [
                TextFormField(
                  controller: _amenitiesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    hintText: 'e.g. AC, TV, WiFi, Mini Bar, Balcony',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.list),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Quick amenity chips
                const Text('Quick Add:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['AC', 'TV', 'WiFi', 'Mini Bar', 'Balcony', 'Jacuzzi', 'Attached Bath', 'Work Desk', 'Lounge Access', 'Smart TV', 'Living Room', 'Private Butler']
                      .map((amenity) => GestureDetector(
                    onTap: () {
                      final current = _amenitiesCtrl.text.trim();
                      final items = current.isEmpty ? <String>[] : current.split(',').map((s) => s.trim()).toList();
                      if (!items.contains(amenity)) {
                        _amenitiesCtrl.text = [...items, amenity].join(', ');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Text(amenity, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ),
                  )).toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isEditMode ? Icons.save : Icons.add_home),
                label: Text(_isEditMode ? 'Update Room' : 'Add Room', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
