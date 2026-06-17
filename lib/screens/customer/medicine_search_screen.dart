import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../screens/customer/medicine_hunt_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_card.dart';
import 'customer_ui.dart';
import 'pharmacy_details_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final _searchController = TextEditingController();

  List<String> suggestions = [];

  /// LOCAL FUZZY SEARCH SUGGESTIONS
  final List<String> medicineSuggestions = [
    "Paracetamol",
    "Azithromycin",
    "Amoxicillin",
    "Dolo 650",
    "Crocin",
    "Cetirizine",
    "Metformin",
    "Insulin",
    "Aspirin",
    "Vitamin C",
    "Ibuprofen",
    "Omeprazole",
    "Pantoprazole",
    "ORS",
    "Cough Syrup",
    "Atorvastatin",
    "Levocetirizine",
    "Diclofenac",
    "Calcium Tablet",
    "Multivitamin",
    "Mefhal",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// SIMPLE FUZZY SEARCH
  void _onSearchChanged(String value) {
    setState(() {
      suggestions = medicineSuggestions
          .where(
            (medicine) =>
                medicine.toLowerCase().contains(
                      value.toLowerCase(),
                    ) ||
                _levenshtein(
                      medicine.toLowerCase(),
                      value.toLowerCase(),
                    ) <=
                    3,
          )
          .toList();
    });
  }

  /// LEVENSHTEIN DISTANCE
  int _levenshtein(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<List<int>> matrix = List.generate(
      s.length + 1,
      (i) => List.filled(t.length + 1, 0),
    );

    for (int i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFFBF8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Medicine Search',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.teal.shade900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: CustomerScreenBackground(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: CustomerHeroCard(
                title: 'Search Medicines',
                subtitle:
                    'Find nearby pharmacies with available stock, pricing, and pickup options instantly.',
                icon: Icons.medication_rounded,
                badges: [
                  CustomerPill(
                    icon: Icons.flash_on_outlined,
                    label: 'Fast lookup',
                  ),
                  CustomerPill(
                    icon: Icons.inventory_2_outlined,
                    label: 'Live inventory',
                  ),
                ],
              ),
            ),

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.04 * 255).round()),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  onSubmitted: provider.searchMedicine,
                  decoration: InputDecoration(
                    hintText: "Search medicine name...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.teal.shade700,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        provider.searchMedicine(
                          _searchController.text,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            /// FUZZY SUGGESTIONS
            if (suggestions.isNotEmpty && _searchController.text.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.04 * 255).round()),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: suggestions.take(5).map((item) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.teal.withAlpha((0.1 * 255).round()),
                        child: Icon(
                          Icons.medication,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      title: Text(item),
                      onTap: () {
                        _searchController.text = item;

                        provider.searchMedicine(
                          item,
                        );

                        setState(() {
                          suggestions = [];
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 10),
            if (_searchController.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Use Medicine Hunt Mode'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicineHuntScreen(
                          query: _searchController.text,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),

            /// RESULTS
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildResults(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(CustomerProvider provider) {
    if (provider.isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        height: 300,
        child: Column(
          children: [
            ShimmerPlaceholder(
              width: double.infinity,
              height: 110,
              borderRadius: 24,
            ),
            SizedBox(height: 14),
            ShimmerPlaceholder(
              width: double.infinity,
              height: 110,
              borderRadius: 24,
            ),
          ],
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return const SizedBox(
        key: ValueKey('empty'),
        height: 300,
        child: EmptyState(
          icon: Icons.medication_outlined,
          title: 'Search for medicine',
          message:
              'Enter a medicine name to see nearby available stock.',
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final result = provider.searchResults[index];

        return AnimatedStaggerItem(
          delay: index * 60,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: AnimatedPressScale(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PharmacyDetailsScreen(
                      stock: result.stock,
                      pharmacy: result.pharmacy,
                      distanceKm: result.distanceKm,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withAlpha((0.04 * 255).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: StockCard(
                  stock: result.stock,
                  pharmacy: result.pharmacy,
                  distanceKm: result.distanceKm,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
