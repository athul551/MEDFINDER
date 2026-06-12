import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stock_card.dart';

import '../profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'customer_ui.dart';
import 'medicine_search_screen.dart';
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

    Future.microtask(
      customerProvider.loadCurrentLocation,
    );
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
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
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              user?.name ?? 'Customer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
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
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ask Jasper'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Colors.white.withAlpha((0.14 * 255).round()),
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationError,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                  return const SizedBox(
                    height: 220,
                    child: LoadingView(
                      message: 'Loading stock...',
                    ),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const SizedBox(
                    height: 220,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No stock yet',
                      message: 'Pharmacy stock will appear here.',
                    ),
                  );
                }

                return Column(
                  children: items.take(6).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.04 * 255).round()),
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
    return CustomerSurfaceCard(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
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
    );
  }
}
