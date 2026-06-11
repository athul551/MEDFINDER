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
  DateTime _pickupTime = DateTime.now().add(const Duration(hours: 2));
  Uint8List? _prescriptionBytes;
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
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
      );
      final reservationId = await firestore.createReservation(reservation);
      if (mounted) {
        showAppSnackBar(context, 'Reservation request sent.');
        final shouldReview = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rate your reservation?'),
            content: const Text(
              'Would you like to rate your reservation experience at this pharmacy?',
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
      appBar: AppBar(title: const Text('Reserve medicine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(widget.stock.medicineName),
                subtitle: Text(widget.pharmacy.name),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _quantityController,
              label: 'Quantity',
              keyboardType: TextInputType.number,
              validator: (value) =>
                  Validators.positiveNumber(value, label: 'Quantity'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Pickup time'),
              subtitle: Text(_pickupTime.toLocal().toString()),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _selectPickupTime,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(
                _prescriptionBytes == null
                    ? 'Upload prescription'
                    : 'Prescription selected',
              ),
              onPressed: _uploadPrescription,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Confirm reservation',
              icon: Icons.check_circle_outline,
              isLoading: _isSaving,
              onPressed: _reserve,
            ),
          ],
        ),
      ),
    );
  }
}
