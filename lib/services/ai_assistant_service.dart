import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/pharmacy.dart';
import '../models/stock_item.dart';
import 'firestore_service.dart';

class AIAssistantService {
  AIAssistantService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final FirestoreService _firestoreService;

  bool get _hasApiKey => _apiKey.trim().isNotEmpty;

  Future<String> answerQuestion(String question) async {
    final prompt = question.trim();
    if (prompt.isEmpty) {
      return 'Ask Jasper a question such as "Where can I find Dolo 650?" or "Which pharmacy near me has insulin?"';
    }

    final stocks = await _retrieveRelevantStock(prompt);
    final pharmacyIds = stocks.map((stock) => stock.pharmacyId).toSet().toList();
    final pharmacies = await _firestoreService.getPharmaciesByIds(pharmacyIds);

    if (!_hasApiKey) {
      return _buildFallbackAnswer(prompt, stocks, pharmacies);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      final geminiPrompt = _buildGeminiPrompt(prompt, stocks, pharmacies);
      final response = await model.generateContent([Content.text(geminiPrompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return _buildFallbackAnswer(prompt, stocks, pharmacies);
      }
      return text.trim();
    } catch (error) {
      return _buildFallbackAnswer(prompt, stocks, pharmacies);
    }
  }

  Future<List<StockItem>> _retrieveRelevantStock(String question) async {
    final normalized = question.toLowerCase();
    final medicines = await _firestoreService.searchMedicinesByFreeText(question);
    final stockItems = <StockItem>{};

    for (final medicine in medicines) {
      final stocks = await _firestoreService.searchStockByMedicineNameOnce(medicine.name);
      stockItems.addAll(stocks.where((stock) => stock.isAvailable));
    }

    if (stockItems.isEmpty) {
      final directStocks = await _firestoreService.searchStockByMedicineNameOnce(question);
      stockItems.addAll(directStocks.where((stock) => stock.isAvailable));
    }

    if (stockItems.isEmpty && normalized.contains('available')) {
      final allStocks = await _firestoreService.searchStockByMedicineNameOnce('');
      stockItems.addAll(allStocks.where((stock) => stock.isAvailable));
    }

    return stockItems.toList();
  }

  String _buildGeminiPrompt(
    String question,
    List<StockItem> stocks,
    List<Pharmacy> pharmacies,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('You are Jasper, the MedFinder assistant.');
    buffer.writeln('Answer any question the user asks.');
    buffer.writeln('If the question is about medicine availability or pharmacies, use the store data below.');
    buffer.writeln('For general questions about medicines, side effects, dosage, or health, provide helpful information.');
    buffer.writeln();
    buffer.writeln('Question: $question');
    buffer.writeln();
    buffer.writeln('Available store data:');

    if (stocks.isEmpty) {
      buffer.writeln('(No matching stock data available)');
    } else {
      final pharmacyMap = {for (var pharmacy in pharmacies) pharmacy.pharmacyId: pharmacy};
      for (final stock in stocks) {
        final pharmacy = pharmacyMap[stock.pharmacyId];
        buffer.writeln(
          '- ${stock.medicineName} at ${pharmacy?.name ?? 'Unknown pharmacy'}: ${stock.quantity} unit(s) available, price ${stock.price.toStringAsFixed(2)}, address ${pharmacy?.address ?? 'unknown'}, phone ${pharmacy?.phone ?? 'unknown'}.',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('Write a concise, friendly, and helpful answer as Jasper.');
    return buffer.toString();
  }

  String _buildFallbackAnswer(
    String question,
    List<StockItem> stocks,
    List<Pharmacy> pharmacies,
  ) {
    if (stocks.isEmpty) {
      return 'Jasper could not find a matching available medicine for "$question". Please try again later or adjust the medicine name.';
    }

    final pharmacyMap = {for (var pharmacy in pharmacies) pharmacy.pharmacyId: pharmacy};
    final lines = stocks.take(5).map((stock) {
      final pharmacy = pharmacyMap[stock.pharmacyId];
      return '${stock.medicineName} is available at ${pharmacy?.name ?? 'a nearby pharmacy'} (${pharmacy?.address ?? 'address unknown'}) with ${stock.quantity} unit(s) in stock.';
    }).join(' ');

    return 'Here is what I found: $lines';
  }
}
