import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stock_card.dart';
import '../customer/customer_ui.dart';
import '../profile_screen.dart';
import 'add_edit_medicine_screen.dart';
import 'pharmacy_reviews_screen.dart';
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
          PharmacyReviewsScreen(pharmacy: pharmacy),
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
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: 'Reviews',
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
        title: Text(
          'Pharmacy Dashboard',
          style: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade900),
        actions: [
          IconButton(
            tooltip: 'Add medicine',
            icon: Icon(Icons.add, color: Colors.teal.shade700),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditMedicineScreen(pharmacy: pharmacy),
              ),
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.teal.shade700),
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
      body: CustomerScreenBackground(
        child: StreamBuilder<List<StockItem>>(
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
              return const LoadingView(message: 'Loading dashboard...');
            }
            final stock = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                AnimatedStaggerItem(
                  delay: 0,
                  child: _PharmacyHeaderCard(pharmacy: pharmacy, stockCount: stock.length),
                ),
                const SizedBox(height: 20),
                AnimatedStaggerItem(
                  delay: 100,
                  child: _DashboardStats(stock: stock),
                ),
                const SizedBox(height: 24),
                const AnimatedStaggerItem(
                  delay: 150,
                  child: CustomerSectionHeader(title: 'Medicine Stock'),
                ),
                const SizedBox(height: 12),
                if (stock.isEmpty)
                  const AnimatedStaggerItem(
                    delay: 200,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No stock added',
                      message: 'Add your first medicine to start receiving reservations.',
                    ),
                  )
                else
                  ...stock.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: AnimatedStaggerItem(
                            delay: 200 + entry.key * 50,
                            child: AnimatedPressScale(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditMedicineScreen(
                                    pharmacy: pharmacy,
                                    stockItem: entry.value,
                                  ),
                                ),
                              ),
                              child: StockCard(
                                stock: entry.value,
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
                                            stockItem: entry.value,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: entry.value.isAvailable,
                                      onChanged: (value) => context
                                          .read<PharmacyProvider>()
                                          .setAvailability(entry.value.stockId, value),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
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
                await auth.deleteAccount();
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

class _PharmacyHeaderCard extends StatelessWidget {
  const _PharmacyHeaderCard({required this.pharmacy, required this.stockCount});

  final Pharmacy pharmacy;
  final int stockCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004D40),
            Color(0xFF00796B),
            Color(0xFF009688),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withAlpha((0.28 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.14 * 255).round()),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacy.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pharmacy account active',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white.withAlpha(
                                  (0.9 * 255).round(),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.16 * 255).round()),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.18 * 255).round()),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.16 * 255).round()),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.18 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$stockCount medicines in stock',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.stock});

  final List<StockItem> stock;

  @override
  Widget build(BuildContext context) {
    final available = stock.where((item) => item.isAvailable).length;
    final lowStock = stock.where((item) => item.isLowStock).length;

    return Row(
      children: [
        Expanded(
          child: CustomerStatCard(
            icon: Icons.inventory,
            label: 'Total Items',
            value: stock.length.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomerStatCard(
            icon: Icons.check_circle,
            label: 'Available',
            value: available.toString(),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomerStatCard(
            icon: Icons.warning_amber,
            label: 'Low Stock',
            value: lowStock.toString(),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}
