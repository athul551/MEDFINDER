import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reservation.dart';
import '../../providers/app_auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_card.dart';

import '../profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'customer_ui.dart';
import 'medicine_search_screen.dart';
import 'my_subscriptions_screen.dart';
import 'pharmacy_list_screen.dart';
import 'reservation_history_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final customerProvider = context.read<CustomerProvider>();
    Future.microtask(customerProvider.loadCurrentLocation);
    Future.microtask(customerProvider.loadRecentSearches);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _CustomerOverview(),
      const MedicineSearchScreen(),
      const ReservationHistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        height: 72,
        elevation: 10,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.teal.withAlpha((0.16 * 255).round()),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24),
            selectedIcon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search, size: 24),
            selectedIcon: Icon(Icons.search, size: 24),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, size: 24),
            selectedIcon: Icon(Icons.receipt_long, size: 24),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 24),
            selectedIcon: Icon(Icons.person, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CustomerOverview extends StatelessWidget {
  const _CustomerOverview();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().appUser;
    final locationError = context.watch<CustomerProvider>().errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome 👋',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              user?.name ?? 'Customer',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.teal.shade900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha((0.08 * 255).round()),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                tooltip: 'Refresh location',
                icon: Icon(
                  Icons.my_location,
                  color: Colors.teal.shade700,
                  size: 22,
                ),
                onPressed: () {
                  context.read<CustomerProvider>().loadCurrentLocation();
                },
              ),
            ),
          ),
        ],
      ),
      body: CustomerScreenBackground(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            CustomerHeroCard(
              title: 'Find Medicines Instantly',
              subtitle:
                  'Search verified pharmacies, compare availability, and reserve pickup in a few taps.',
              icon: Icons.local_hospital_rounded,
              badges: const [
                CustomerPill(
                  icon: Icons.verified_outlined,
                  label: 'Verified stock',
                ),
                CustomerPill(
                  icon: Icons.near_me_outlined,
                  label: 'Nearby stores',
                ),
              ],
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Search Medicine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicineSearchScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text(
                      'Ask Jasper',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Colors.white.withAlpha((0.14 * 255).round()),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.white.withAlpha((0.18 * 255).round()),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIAssistantScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.storefront_outlined,
                    title: 'Pharmacies',
                    subtitle: 'Browse verified nearby stores',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PharmacyListScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Reservations',
                    subtitle: 'Track pickup status quickly',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReservationHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            /// LOCATION ERROR
            if (locationError != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withAlpha((0.2 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_off_outlined,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location unavailable',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationError,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            /// HEALTH DASHBOARD
            if (user != null)
              _CustomerHealthDashboard(userId: user.uid),

            const SizedBox(height: 18),

            /// SUBSCRIPTIONS ENTRY
            AnimatedStaggerItem(
              delay: 180,
              child: AnimatedPressScale(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySubscriptionsScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
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
                        color: const Color(0xFF004D40)
                            .withAlpha((0.2 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.16 * 255).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Medicine Subscriptions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Auto refills & reminders for your regular medicines',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white.withAlpha((0.85 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withAlpha((0.8 * 255).round()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            CustomerSectionHeader(
              title: 'Recently Updated Stock',
              actionLabel: 'View all',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicineSearchScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            /// STOCK LIST
            StreamBuilder(
              stream:
                  context.read<FirestoreService>().searchStockByMedicineName(
                        '',
                      ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _ShimmerStockList();
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      key: const ValueKey('empty'),
                      height: 140,
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No stock yet',
                        message: 'Pharmacy stock will appear here.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: items.take(6).toList().asMap().entries.map((e) {
                    final index = e.key;
                    final item = e.value;
                    return AnimatedStaggerItem(
                      delay: index * 60,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AnimatedPressScale(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicineSearchScreen(),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.04 * 255).round()),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: StockCard(
                              stock: item,
                              trailing: null,
                            ),
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
      ),
    );
  }
}

class _CustomerHealthDashboard extends StatelessWidget {
  final String userId;

  const _CustomerHealthDashboard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reservation>>(
      stream: context.read<FirestoreService>().watchReservationsForUser(userId),
      builder: (context, snapshot) {
        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        final totalCount = reservations.length;

        final thisMonthReservations = reservations.where((r) =>
            r.reservedAt.isAfter(monthStart)).toList();
        final thisMonthPickedUp = thisMonthReservations
            .where((r) => r.status == ReservationStatus.pickedUp);
        final monthlyPurchases =
            thisMonthPickedUp.fold<int>(0, (sum, r) => sum + r.quantity);

        final pharmacyCounts = <String, int>{};
        for (final r in reservations) {
          pharmacyCounts.update(
            r.pharmacyName,
            (v) => v + 1,
            ifAbsent: () => 1,
          );
        }
        final sorted = pharmacyCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final favorite = sorted.isNotEmpty ? sorted.first.key : 'N/A';

        final monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final monthlyData = <String, int>{};
        for (int i = 5; i >= 0; i--) {
          final m = now.month - i;
          final label = m <= 0
              ? '${monthNames[12 + m - 1]} ${now.year - 1}'
              : monthNames[m - 1];
          monthlyData[label] = 0;
        }
        for (final r in reservations.where(
            (r) => r.status == ReservationStatus.pickedUp)) {
          final monthsAgo = (now.year - r.reservedAt.year) * 12 +
              (now.month - r.reservedAt.month);
          if (monthsAgo >= 0 && monthsAgo < 6) {
            final m = now.month - monthsAgo;
            final label = m <= 0
                ? '${monthNames[12 + m - 1]} ${now.year - 1}'
                : monthNames[m - 1];
            monthlyData[label] = (monthlyData[label] ?? 0) + r.quantity;
          }
        }

        return Column(
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
                    Icons.favorite_outline,
                    color: Color(0xFF00796B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Your Health Dashboard',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _HealthStatCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Total Reservations',
                    value: totalCount.toString(),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HealthStatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'This Month',
                    value: monthlyPurchases.toString(),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HealthStatCard(
                    icon: Icons.storefront_outlined,
                    label: 'Favorite Pharmacy',
                    value: favorite.length > 12
                        ? '${favorite.substring(0, 10)}..'
                        : favorite,
                    color: AppColors.warning,
                    valueSize: 13,
                  ),
                ),
              ],
            ),
            if (monthlyData.values.any((v) => v > 0)) ...[
              const SizedBox(height: 20),
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '6-Month Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MonthlyBarChart(data: monthlyData),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _RecentSearchesCard(),
          ],
        );
      },
    );
  }
}

class _HealthStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double valueSize;

  const _HealthStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueSize = 18,
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
              fontSize: valueSize,
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

class _RecentSearchesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final recentSearches = context.watch<CustomerProvider>().recentSearches;
    if (recentSearches.isEmpty) return const SizedBox.shrink();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF004D40),
                ),
              ),
              InkWell(
                onTap: () =>
                    context.read<CustomerProvider>().clearRecentSearches(),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.take(6).map((query) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicineSearchScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha((0.08 * 255).round()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        query,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 100,
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
                          const Color(0xFF009688).withAlpha((0.5 * 255).round()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key.split(' ').first,
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

class _ShimmerStockList extends StatelessWidget {
  const _ShimmerStockList();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 340,
      child: Column(
        children: [
          _ShimmerRow(),
          SizedBox(height: 14),
          _ShimmerRow(),
          SizedBox(height: 14),
          _ShimmerRow(),
        ],
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      width: double.infinity,
      height: 100,
      borderRadius: 22,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressScale(
      onTap: onTap,
      child: CustomerSurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerIconBadge(
              icon: icon,
              color: color,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
