import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stock_card.dart';
import '../profile_screen.dart';
import 'add_edit_medicine_screen.dart';
import 'reservations_management_screen.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().appUser;
    if (user == null) {
      return const Scaffold(body: LoadingView(message: 'Loading profile...'));
    }
    return StreamBuilder<Pharmacy?>(
      stream: context.read<FirestoreService>().watchPharmacyForOwner(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(message: 'Loading pharmacy...'),
          );
        }
        final pharmacy = snapshot.data;
        if (pharmacy == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No pharmacy profile',
              message: 'Your pharmacy profile was not found.',
            ),
          );
        }
        final screens = [
          _StockOverview(pharmacy: pharmacy),
          ReservationsManagementScreen(pharmacy: pharmacy),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: screens[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                label: 'Reservations',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockOverview extends StatelessWidget {
  const _StockOverview({required this.pharmacy});

  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy dashboard'),
        actions: [
          IconButton(
            tooltip: 'Add medicine',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditMedicineScreen(pharmacy: pharmacy),
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete pharmacy', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () => _showDeletePharmacyConfirmation(context, pharmacy),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(pharmacy.name),
              subtitle: const Text('Pharmacy account active'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Stock', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<StockItem>>(
            stream: context.read<FirestoreService>().watchStockForPharmacy(
                  pharmacy.pharmacyId,
                ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load stock',
                  message: snapshot.error.toString(),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: LoadingView(message: 'Loading stock...'),
                );
              }
              final stock = snapshot.data ?? [];
              if (stock.isEmpty) {
                return const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No stock added',
                  message:
                      'Add your first medicine to start receiving reservations.',
                );
              }
              return Column(
                children: stock.map((item) {
                  return StockCard(
                    stock: item,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit stock',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditMedicineScreen(
                                pharmacy: pharmacy,
                                stockItem: item,
                              ),
                            ),
                          ),
                        ),
                        Switch(
                          value: item.isAvailable,
                          onChanged: (value) => context
                              .read<PharmacyProvider>()
                              .setAvailability(item.stockId, value),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditMedicineScreen(
                          pharmacy: pharmacy,
                          stockItem: item,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add stock'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditMedicineScreen(pharmacy: pharmacy),
          ),
        ),
      ),
    );
  }

  void _showDeletePharmacyConfirmation(BuildContext context, Pharmacy pharmacy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pharmacy?'),
        content: const Text(
          'This will permanently delete your pharmacy and all associated data including stock and reservations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final auth = context.read<AppAuthProvider>();
                // Delete account - this will set appUser to null
                await auth.deleteAccount();
                // AuthGate will automatically handle the navigation to login
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete pharmacy: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
