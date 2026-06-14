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
import 'medicine_search_screen.dart';
import 'reservation_history_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() =>
      _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _index = 0;

  static const double _navHeight = 68;


  @override
  void initState() {
    super.initState();

    final customerProvider =
        context.read<CustomerProvider>();

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
        selectedIndex: _index,
        height: 68,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black12,
        indicatorColor: Colors.teal.withOpacity(0.12),

        // NOTE: labelTextStyle isn't available on this Flutter version.
        // Keep only the supported NavigationBar properties.

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
    final user =
        context.watch<AppAuthProvider>().appUser;

    final locationError =
        context.watch<CustomerProvider>().errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
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
            const SizedBox(height: 2),
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
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.teal.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                tooltip: 'Refresh location',
                icon: Icon(
                  Icons.my_location,
                  color: Colors.teal.shade700,
                  size: 22,
                ),
                onPressed: () {
                  context
                      .read<CustomerProvider>()
                      .loadCurrentLocation();
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          /// HERO SECTION
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade500,
                  Colors.teal.shade700,
                  Colors.teal.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.teal.shade600.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find Medicines Instantly',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Search nearby verified pharmacies and reserve medicines easily.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text(
                      'Search Medicine',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal.shade900,
                      elevation: 0,
                      shadowColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 58,
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
                      backgroundColor: Colors.white.withOpacity(0.18),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
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
          ),

          /// LOCATION ERROR
          if (locationError != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.location_off_outlined,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locationError,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          /// TITLE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Updated Stock',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.teal.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.teal.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// STOCK LIST
          StreamBuilder(
            stream: context
                .read<FirestoreService>()
                .searchStockByMedicineName(
                  '',
                ),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
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
                children: items
                    .take(6)
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: StockCard(
                              stock: item,
                              trailing: null,
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// QUICK ACTION CARD
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
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

