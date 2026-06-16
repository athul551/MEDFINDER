import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medicine_subscription.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/snackbars.dart';
import '../customer/customer_ui.dart';

class CreateSubscriptionScreen extends StatefulWidget {
  const CreateSubscriptionScreen({
    super.key,
    this.medicineName,
    this.medicineId,
    this.pharmacyId,
    this.pharmacyName,
  });

  final String? medicineName;
  final String? medicineId;
  final String? pharmacyId;
  final String? pharmacyName;

  @override
  State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _medicineController;
  late final TextEditingController _quantityController;
  int _frequencyDays = 30;
  bool _autoReminder = true;
  bool _autoReservation = false;

  final _frequencies = [
    (label: 'Every 7 days', days: 7),
    (label: 'Every 15 days', days: 15),
    (label: 'Every 30 days', days: 30),
    (label: 'Every 60 days', days: 60),
    (label: 'Custom', days: -1),
  ];

  @override
  void initState() {
    super.initState();
    _medicineController = TextEditingController(text: widget.medicineName ?? '');
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) return;

    final sub = MedicineSubscription(
      subscriptionId: '',
      userId: user.uid,
      medicineName: _medicineController.text.trim(),
      medicineId: widget.medicineId,
      pharmacyId: widget.pharmacyId,
      pharmacyName: widget.pharmacyName,
      frequencyDays: _frequencyDays,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      nextRefillDate: DateTime.now().add(Duration(days: _frequencyDays)),
      lastRefillDate: DateTime.now(),
      autoReminder: _autoReminder,
      autoReservation: _autoReservation,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      await context.read<SubscriptionProvider>().createSubscription(sub);
      if (mounted) {
        showAppSnackBar(context, 'Subscription created!');
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed: $error', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<SubscriptionProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Subscription'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      body: CustomerScreenBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.medication_outlined,
                        title: 'Medicine Details',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _medicineController,
                        decoration: _inputDecoration(
                          label: 'Medicine Name',
                          hint: 'e.g. Insulin',
                          icon: Icons.medication,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: _inputDecoration(
                          label: 'Quantity per Refill',
                          hint: 'e.g. 2',
                          icon: Icons.numbers,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                                ? 'Enter a valid quantity'
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.repeat_outlined,
                        title: 'Frequency',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _frequencies.map((f) {
                          final selected = _frequencyDays == f.days ||
                              (f.days == -1 && !_frequencies.any(
                                  (x) => x.days == _frequencyDays));
                          return ChoiceChip(
                            label: Text(f.label),
                            selected: selected,
                            onSelected: (v) {
                              if (v && f.days > 0) {
                                setState(() => _frequencyDays = f.days);
                              } else if (v && f.days == -1) {
                                _showCustomFrequency();
                              }
                            },
                            selectedColor: const Color(0xFF00796B),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_frequencyDays > 0 && _frequencyDays != 7 &&
                          _frequencyDays != 15 && _frequencyDays != 30 &&
                          _frequencyDays != 60)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Custom: $_frequencyDays days',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.tune_outlined,
                        title: 'Preferences',
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Auto Reminder'),
                        subtitle: const Text('Get notified before refill'),
                        value: _autoReminder,
                        onChanged: (v) => setState(() => _autoReminder = v),
                        activeTrackColor: const Color(0xFF00796B).withAlpha((0.4 * 255).round()),
                        activeThumbColor: const Color(0xFF00796B),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: const Text('Auto Reservation'),
                        subtitle: const Text('Automatically reserve when refill is due'),
                        value: _autoReservation,
                        onChanged: (v) => setState(() => _autoReservation = v),
                        activeTrackColor: const Color(0xFF00796B).withAlpha((0.4 * 255).round()),
                        activeThumbColor: const Color(0xFF00796B),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                if (widget.pharmacyName != null) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.storefront_outlined,
                          title: 'Preferred Pharmacy',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.store, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              widget.pharmacyName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF004D40),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(isSaving ? 'Creating...' : 'Subscribe'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isSaving ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomFrequency() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Frequency'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Days',
            hintText: 'Enter number of days',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text);
              if (days != null && days > 0) {
                setState(() => _frequencyDays = days);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.94 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withAlpha((0.06 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF00796B)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
        ),
      ],
    );
  }
}
