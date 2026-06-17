import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/reservation.dart';
import '../../models/stock_item.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/snackbars.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'customer_ui.dart';
import 'prescription_upload_screen.dart';
import 'write_review_screen.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    required this.stock,
    required this.pharmacy,
  });

  final StockItem stock;
  final Pharmacy pharmacy;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _pickupTime = DateTime.now().add(const Duration(hours: 2));
  Uint8List? _prescriptionBytes;
  bool _isSaving = false;
  bool _isDelivery = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().appUser;
    if (user?.defaultAddress != null) {
      _addressController.text = user!.defaultAddress!;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPickupTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
      initialDate: _pickupTime,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupTime),
    );
    if (time == null) return;
    setState(() {
      _pickupTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _uploadPrescription() async {
    final bytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(builder: (_) => const PrescriptionUploadScreen()),
    );
    if (bytes != null) setState(() => _prescriptionBytes = bytes);
  }

  Future<void> _reserve() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AppAuthProvider>().appUser;
    if (user == null) return;
    final firestore = context.read<FirestoreService>();
    setState(() => _isSaving = true);
    try {
      String? prescriptionUrl;
      if (_prescriptionBytes != null) {
        prescriptionUrl = await StorageService().uploadPrescription(
          userId: user.uid,
          bytes: _prescriptionBytes!,
        );
      }
      final reservation = Reservation(
        reservationId: '',
        userId: user.uid,
        pharmacyId: widget.pharmacy.pharmacyId,
        medicineId: widget.stock.medicineId,
        medicineName: widget.stock.medicineName,
        pharmacyName: widget.pharmacy.name,
        quantity: int.parse(_quantityController.text),
        status: ReservationStatus.pending,
        reservedAt: DateTime.now(),
        pickupTime: _pickupTime,
        prescriptionUrl: prescriptionUrl,
        isDelivery: _isDelivery,
        deliveryAddress:
            _isDelivery ? _addressController.text.trim() : null,
        deliveryFee: _isDelivery ? widget.pharmacy.deliveryFee : null,
        deliveryNotes:
            _isDelivery ? _notesController.text.trim() : null,
      );
      final reservationId = await firestore.createReservation(reservation);
      if (mounted) {
        final msg = _isDelivery
            ? 'Delivery request sent.'
            : 'Reservation request sent.';
        showAppSnackBar(context, msg);
        final shouldReview = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rate your experience?'),
            content: const Text(
              'Would you like to rate your experience at this pharmacy?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Rate now'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (shouldReview == true) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteReviewScreen(
                pharmacy: widget.pharmacy,
                triggerType: ReviewTrigger.reservation,
                reservationId: reservationId,
              ),
            ),
          );
        }
        if (mounted) Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _isDelivery ? 'Request Delivery' : 'Reserve Medicine',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CustomerIconBadge(
                      icon: Icons.medication_outlined,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stock.medicineName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.pharmacy.name,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodButton(
                            icon: Icons.store_outlined,
                            label: 'Pickup',
                            selected: !_isDelivery,
                            onTap: () => setState(() => _isDelivery = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MethodButton(
                            icon: Icons.delivery_dining_outlined,
                            label: 'Delivery',
                            selected: _isDelivery,
                            onTap: widget.pharmacy.deliveryAvailable
                                ? () => setState(() => _isDelivery = true)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.pharmacy.deliveryAvailable) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Delivery not available from this pharmacy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    if (_isDelivery && widget.pharmacy.deliveryFee > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withAlpha((0.08 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.teal.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Delivery fee: ₹${widget.pharmacy.deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          Validators.positiveNumber(value, label: 'Quantity'),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isDelivery
                                    ? Icons.delivery_dining_outlined
                                    : Icons.schedule,
                                color: Colors.teal.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isDelivery
                                    ? 'Preferred delivery time'
                                    : 'Pickup time',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade900,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon:
                                    const Icon(Icons.edit_calendar_outlined),
                                onPressed: _selectPickupTime,
                                color: Colors.teal.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickupTime.toLocal().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isDelivery) ...[
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _addressController,
                        label: 'Delivery address',
                        maxLines: 3,
                        validator: (value) {
                          if (_isDelivery &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Enter a delivery address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _notesController,
                        label: 'Delivery notes (optional)',
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 20),
                        label: Text(
                          _prescriptionBytes == null
                              ? 'Upload prescription'
                              : 'Prescription selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: _uploadPrescription,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade700,
                          side: BorderSide(color: Colors.teal.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _isDelivery ? 'Request delivery' : 'Confirm reservation',
                icon: _isDelivery
                    ? Icons.delivery_dining_outlined
                    : Icons.check_circle_outline,
                isLoading: _isSaving,
                onPressed: _reserve,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodButton({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? Colors.teal.withAlpha((0.1 * 255).round())
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.teal.shade700 : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.teal.shade700 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
