import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../screens/customer/medicine_hunt_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/stock_card.dart';
import 'pharmacy_details_screen.dart';

class MedicineSearchScreen extends StatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  State<MedicineSearchScreen> createState() =>
      _MedicineSearchScreenState();
}

class _MedicineSearchScreenState
    extends State<MedicineSearchScreen> {

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

    final provider =
        context.watch<CustomerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,

        title: Text(
          'Medicine Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ),

      body: Column(
        children: [

          /// TOP HERO SECTION
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(28),

              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade600,
                  Colors.teal.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.teal.withAlpha((0.25 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      const Text(
                        "Search Medicines",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Find nearby pharmacies with available medicine stock instantly.",
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color:
                        Colors.white.withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                ),

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha((0.04 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: TextField(
                controller: _searchController,

                textInputAction:
                    TextInputAction.search,

                onChanged: _onSearchChanged,

                onSubmitted:
                    provider.searchMedicine,

                decoration: InputDecoration(
                  hintText:
                      "Search medicine name...",

                  border: InputBorder.none,

                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 18,
                  ),

                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.teal.shade700,
                  ),

                  suffixIcon: IconButton(
                    tooltip: 'Search',

                    icon: Container(
                      padding:
                          const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius:
                            BorderRadius.circular(
                                12),
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
          if (suggestions.isNotEmpty &&
              _searchController.text.isNotEmpty)

            Container(
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha((0.04 * 255).round()),
                    blurRadius: 10,
                  ),
                ],
              ),

              child: Column(
                children:
                    suggestions.take(5).map((item) {

                  return ListTile(

                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.teal.withAlpha((0.1 * 255).round()),

                      child: Icon(
                        Icons.medication,
                        color:
                            Colors.teal.shade700,
                      ),
                    ),

                    title: Text(item),

                    onTap: () {

                      _searchController.text =
                          item;

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
            child: Builder(
              builder: (context) {

                if (provider.isLoading) {

                  return const LoadingView(
                    message:
                        'Finding pharmacies...',
                  );
                }

                if (provider.searchResults.isEmpty) {

                  return const EmptyState(
                    icon:
                        Icons.medication_outlined,

                    title:
                        'Search for medicine',

                    message:
                        'Enter a medicine name to see nearby available stock.',
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      provider.searchResults.length,

                  itemBuilder:
                      (context, index) {

                    final result =
                        provider.searchResults[
                            index];

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                                  24),

                          boxShadow: [

                            BoxShadow(
                              color: Colors.black.withAlpha((0.04 * 255).round()),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: StockCard(
                          stock: result.stock,
                          pharmacy:
                              result.pharmacy,

                          distanceKm:
                              result.distanceKm,

                          onTap: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    PharmacyDetailsScreen(
                                  stock:
                                      result.stock,

                                  pharmacy:
                                      result
                                          .pharmacy,

                                  distanceKm:
                                      result
                                          .distanceKm,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}