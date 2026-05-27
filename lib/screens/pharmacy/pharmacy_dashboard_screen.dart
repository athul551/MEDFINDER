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
                    trailing: Switch(
                      value: item.isAvailable,
                      onChanged: (value) => context
                          .read<PharmacyProvider>()
                          .setAvailability(item.stockId, value),
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
}
