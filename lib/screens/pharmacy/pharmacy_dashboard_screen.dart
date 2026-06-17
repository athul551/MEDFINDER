import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pharmacy.dart';
import '../../models/reservation.dart';
import '../../models/stock_item.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/snackbars.dart';
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
                const SizedBox(height: 20),
                AnimatedStaggerItem(
                  delay: 150,
                  child: _DashboardAnalytics(pharmacy: pharmacy, stock: stock),
                ),
                const SizedBox(height: 20),
                AnimatedStaggerItem(
                  delay: 180,
                  child: _DeliverySettingsCard(pharmacy: pharmacy),
                ),
                const SizedBox(height: 24),
                const AnimatedStaggerItem(
                  delay: 200,
                  child: CustomerSectionHeader(title: 'Medicine Stock'),
                ),
                const SizedBox(height: 12),
                if (stock.isEmpty)
                  const AnimatedStaggerItem(
                    delay: 250,
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
                            delay: 250 + entry.key * 50,
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

class _DashboardAnalytics extends StatelessWidget {
  const _DashboardAnalytics({required this.pharmacy, required this.stock});

  final Pharmacy pharmacy;
  final List<StockItem> stock;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reservation>>(
      stream: context.read<FirestoreService>().watchReservationsForPharmacy(
            pharmacy.pharmacyId,
          ),
      builder: (context, snapshot) {
        final reservations = snapshot.data ?? [];

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final todayReservations = reservations.where((r) =>
            r.reservedAt.isAfter(todayStart) &&
            r.status == ReservationStatus.pickedUp).toList();

        final pickedUp = reservations
            .where((r) => r.status == ReservationStatus.pickedUp)
            .toList();

        final dailyCount = todayReservations.length;

        final lowStockItems = stock.where((s) => s.isLowStock).toList();

        double revenue = 0;
        for (final r in pickedUp) {
          final item = stock.where((s) =>
              s.medicineName.toLowerCase() == r.medicineName.toLowerCase()).firstOrNull;
          if (item != null) {
            revenue += item.price * r.quantity;
          }
        }

        final medicineSales = <String, int>{};
        for (final r in pickedUp) {
          medicineSales.update(r.medicineName, (v) => v + r.quantity,
              ifAbsent: () => r.quantity);
        }
        final sortedMedicines = medicineSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topMedicines = sortedMedicines.take(5).toList();

        final weekDays = <String, int>{};
        for (int i = 6; i >= 0; i--) {
          final day = DateTime(now.year, now.month, now.day - i);
          final label = _dayLabel(day);
          weekDays[label] = 0;
        }
        for (final r in reservations.where(
            (r) => r.status == ReservationStatus.pickedUp)) {
          final diff = now.difference(r.reservedAt).inDays;
          if (diff >= 0 && diff <= 6) {
            final label = _dayLabel(r.reservedAt);
            weekDays[label] = (weekDays[label] ?? 0) + r.quantity;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.94 * 255).round()),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade900.withAlpha((0.07 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B).withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFF00796B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticTile(
                      icon: Icons.today_outlined,
                      label: 'Today Picked Up',
                      value: dailyCount.toString(),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticTile(
                      icon: Icons.warning_amber_outlined,
                      label: 'Low Stock Alerts',
                      value: lowStockItems.length.toString(),
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AnalyticTile(
                      icon: Icons.attach_money,
                      label: 'Est. Revenue',
                      value: '₹${revenue.toStringAsFixed(0)}',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (lowStockItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LowStockBanner(items: lowStockItems),
              ],
              if (topMedicines.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Top Selling Medicines',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 10),
                ...topMedicines.map((e) => _TopMedicineRow(
                      name: e.key,
                      quantity: e.value,
                      maxQuantity: topMedicines.first.value,
                    )),
              ],
              if (weekDays.values.any((v) => v > 0)) ...[
                const SizedBox(height: 20),
                const Text(
                  'Weekly Trend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 12),
                _WeeklyBarChart(data: weekDays),
              ],
            ],
          ),
        );
      },
    );
  }

  String _dayLabel(DateTime day) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[day.weekday - 1];
  }
}

class _AnalyticTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AnalyticTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha((0.06 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((0.15 * 255).round())),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  final List<StockItem> items;

  const _LowStockBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((0.06 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''} running low',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 26),
                    Expanded(
                      child: Text(
                        item.medicineName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                '+${items.length - 3} more',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopMedicineRow extends StatelessWidget {
  final String name;
  final int quantity;
  final int maxQuantity;

  const _TopMedicineRow({
    required this.name,
    required this.quantity,
    required this.maxQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxQuantity > 0 ? quantity / maxQuantity : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF004D40),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$quantity sold',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.teal.shade50,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00796B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final fraction = maxVal > 0 ? entry.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 60 * fraction.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF00796B),
                          const Color(0xFF009688).withAlpha((0.6 * 255).round()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DeliverySettingsCard extends StatefulWidget {
  final Pharmacy pharmacy;

  const _DeliverySettingsCard({required this.pharmacy});

  @override
  State<_DeliverySettingsCard> createState() => _DeliverySettingsCardState();
}

class _DeliverySettingsCardState extends State<_DeliverySettingsCard> {
  late bool _deliveryAvailable;
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _deliveryAvailable = widget.pharmacy.deliveryAvailable;
    _feeController = TextEditingController(
      text: widget.pharmacy.deliveryFee > 0
          ? widget.pharmacy.deliveryFee.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fee = double.tryParse(_feeController.text) ?? 0;
    final updated = widget.pharmacy.copyWith(
      deliveryAvailable: _deliveryAvailable,
      deliveryFee: fee,
    );
    await context.read<FirestoreService>().updatePharmacy(updated);
    if (mounted) {
      showAppSnackBar(
        context,
        _deliveryAvailable ? 'Delivery enabled' : 'Delivery disabled',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _deliveryAvailable
                      ? Colors.teal.withAlpha((0.1 * 255).round())
                      : Colors.grey.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.delivery_dining_outlined,
                  color: _deliveryAvailable ? Colors.teal.shade700 : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Home Delivery',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),
              Switch(
                value: _deliveryAvailable,
                activeColor: Colors.teal,
                onChanged: (v) => setState(() => _deliveryAvailable = v),
              ),
            ],
          ),
          if (_deliveryAvailable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Delivery fee (₹)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
