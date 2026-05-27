import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/medicine.dart';
import '../../models/reservation.dart';
import '../../providers/admin_provider.dart';
import '../../providers/app_auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/snackbars.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/reservation_card.dart';
import '../profile_screen.dart';
import 'pharmacy_verification_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin dashboard'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AppAuthProvider>().signOut(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.verified_outlined), text: 'Pharmacies'),
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Categories'),
              Tab(
                icon: Icon(Icons.receipt_long_outlined),
                text: 'Reservations',
              ),
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PharmacyVerificationScreen(),
            _UsersTab(),
            _CategoriesTab(),
            _AllReservationsTab(),
            ProfileScreen(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: context.read<FirestoreService>().watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading users...');
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.people_alt_outlined,
            title: 'No users',
            message: 'Registered users will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(user.name),
                subtitle: Text('${user.email}\n${user.role.label}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AdminProvider>().saveMedicineCategory(
            name: _nameController.text,
            category: _categoryController.text,
            description: _descriptionController.text,
          );
      _nameController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      if (mounted) showAppSnackBar(context, 'Medicine category saved.');
    } catch (error) {
      if (mounted) showAppSnackBar(context, error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    validator: (value) =>
                        Validators.required(value, label: 'Medicine name'),
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    validator: (value) =>
                        Validators.required(value, label: 'Category'),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: admin.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save category'),
                    onPressed: admin.isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Medicine>>(
          stream: context.read<FirestoreService>().watchMedicines(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: LoadingView(message: 'Loading categories...'),
              );
            }
            final medicines = snapshot.data ?? [];
            if (medicines.isEmpty) {
              return const EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories',
                message: 'Saved medicines and categories will appear here.',
              );
            }
            return Column(
              children: medicines.map((medicine) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.medication_liquid_outlined),
                    title: Text(medicine.name),
                    subtitle: Text(medicine.category),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AllReservationsTab extends StatelessWidget {
  const _AllReservationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reservation>>(
      stream: context.read<FirestoreService>().watchAllReservations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Loading reservations...');
        }
        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No reservations',
            message: 'All customer reservations will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return ReservationCard(reservation: reservations[index]);
          },
        );
      },
    );
  }
}
