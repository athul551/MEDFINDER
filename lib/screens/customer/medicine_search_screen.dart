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
    final provider = context.watch<CustomerProvider>();

    // Rebuild cleaned widget tree (fixes syntax issues around conditional widgets)
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,

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

      body: Column(
        children: [

          /// TOP HERO SECTION
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(32),

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
                  color:
                      Colors.teal.withAlpha((0.35 * 255).round()),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color:
                      Colors.teal.shade600.withAlpha((0.2 * 255).round()),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
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
                          fontSize: 26,
                          fontWeight:
                              FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Find nearby pharmacies with available medicine stock instantly.",
                        style: TextStyle(
                          color: Colors.white.withAlpha((0.92 * 255).round()),
                          height: 1.5,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color:
                        Colors.white.withAlpha((0.15 * 255).round()),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),

                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ],
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha((0.06 * 255).round()),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
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

                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),

                  border: InputBorder.none,

                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),

                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.teal.shade700,
                    size: 24,
                  ),

                  suffixIcon: IconButton(
                    tooltip: 'Search',

                    icon: Container(
                      padding:
                          const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                      ),

                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
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
                  const EdgeInsets.fromLTRB(
                20, 12, 20, 0,
              ),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha((0.06 * 255).round()),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),

              child: Column(
                children:
                    suggestions.take(5).map((item) {

                  return ListTile(

                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.teal.withAlpha((0.12 * 255).round()),

                      child: Icon(
                        Icons.medication,
                        color:
                            Colors.teal.shade700,
                        size: 20,
                      ),
                    ),

                    title: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

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

          const SizedBox(height: 16),
          if (_searchController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.local_shipping_outlined, size: 20),
                  label: const Text(
                    'Use Medicine Hunt Mode',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
            ),
          const SizedBox(height: 16),

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
                      const EdgeInsets.fromLTRB(20, 0, 20, 20),

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
                        bottom: 16,
                      ),

                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                                  24),

                          boxShadow: [

                            BoxShadow(
                              color: Colors.black.withAlpha((0.06 * 255).round()),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
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