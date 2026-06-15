import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medicine.dart';
import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../services/firestore_service.dart';
import '../../utils/snackbars.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../customer/customer_ui.dart';

class AddEditMedicineScreen extends StatefulWidget {
  const AddEditMedicineScreen({
    super.key,
    required this.pharmacy,
    this.stockItem,
  });

  final Pharmacy pharmacy;
  final StockItem? stockItem;

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 180));
  bool _isAvailable = true;
  bool _isSaving = false;

  bool get _isEditing => widget.stockItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.stockItem;
    _nameController = TextEditingController(text: item?.medicineName ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: item?.price.toStringAsFixed(2) ?? '',
    );
    if (item != null) {
      _expiryDate = item.expiryDate;
      _isAvailable = item.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _expiryDate,
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final firestore = context.read<FirestoreService>();
      final medicineId = _isEditing
          ? widget.stockItem!.medicineId
          : await firestore.saveMedicine(
              Medicine(
                medicineId: '',
                name: _nameController.text.trim(),
                category: _categoryController.text.trim(),
                description: _descriptionController.text.trim(),
              ),
            );
      final stock = StockItem(
        stockId: widget.stockItem?.stockId ?? '',
        pharmacyId: widget.pharmacy.pharmacyId,
        medicineId: medicineId,
        medicineName: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        expiryDate: _expiryDate,
        isAvailable: _isAvailable,
        updatedAt: DateTime.now(),
      );
      await firestore.saveStock(stock);
      if (mounted) {
        showAppSnackBar(context, 'Medicine stock saved.');
        Navigator.pop(context);
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
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit medicine' : 'Add medicine',
          style: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
      ),
      body: CustomerScreenBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _nameController,
                      label: 'Medicine name',
                      prefixIcon: Icons.medication_outlined,
                      validator: (value) =>
                          Validators.required(value, label: 'Medicine name'),
                    ),
                    if (!_isEditing) ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _categoryController,
                        label: 'Category',
                        prefixIcon: Icons.category_outlined,
                        validator: (value) =>
                            Validators.required(value, label: 'Category'),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomerSurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade900,
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
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _priceController,
                      label: 'Price',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          Validators.positiveNumber(value, label: 'Price'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available'),
                      value: _isAvailable,
                      onChanged: (value) => setState(() => _isAvailable = value),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_outlined, color: Colors.teal.shade700),
                      title: const Text('Expiry date'),
                      subtitle: Text(_expiryDate.toLocal().toString().split(' ').first),
                      trailing: Icon(Icons.edit_calendar_outlined, color: Colors.teal.shade700),
                      onTap: _selectExpiryDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save stock',
                icon: Icons.save_outlined,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
