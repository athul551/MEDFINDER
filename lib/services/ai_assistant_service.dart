import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/pharmacy.dart';
import '../models/stock_item.dart';
import 'firestore_service.dart';

class AIAssistantService {
  AIAssistantService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

    static const _definedApiKey = String.fromEnvironment('GROQ_API_KEY');

    String get _apiKey =>
      (dotenv.env['GROQ_API_KEY'] ?? _definedApiKey).trim();

  bool get _hasApiKey => _apiKey.isNotEmpty;

  Future<String> answerQuestion(String question) async {
    final prompt = question.trim();
    if (prompt.isEmpty) {
      return 'Ask Jasper a question such as "Where can I find Dolo 650?" or "Which pharmacy near me has insulin?"';
    }

    var stocks = <StockItem>[];
    var pharmacies = <Pharmacy>[];
    if (_isAvailabilityQuestion(prompt)) {
      try {
        stocks = await _retrieveRelevantStock(prompt);
        final pharmacyIds = stocks.map((stock) => stock.pharmacyId).toSet().toList();
        pharmacies = await _firestoreService.getPharmaciesByIds(pharmacyIds);
      } catch (_) {
        // The AI can still answer when the store lookup is unavailable.
      }
    }

    if (!_hasApiKey) {
      return 'Jasper is not configured with a Groq API key. Add GROQ_API_KEY to .env and restart the app.';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': dotenv.env['GROQ_MODEL']?.trim() ?? 'openai/gpt-oss-120b',
          'messages': [
            {'role': 'user', 'content': _buildGroqPrompt(prompt, stocks, pharmacies)},
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Jasper could not reach the AI service right now. Please try again shortly.';
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = body['choices'] as List<dynamic>?;
      final message = choices?.firstOrNull as Map<String, dynamic>?;
      final text = (message?['message'] as Map<String, dynamic>?)?['content'] as String?;
      if (text == null || text.trim().isEmpty) {
        return 'Jasper received an empty answer. Please try asking that another way.';
      }
      return _toPlainEnglish(text);
    } catch (error) {
      return 'Jasper could not answer right now. Check your internet connection and try again.';
    }
  }

  bool _isAvailabilityQuestion(String question) {
    const keywords = [
      'available',
      'availability',
      'pharmacy',
      'chemist',
      'stock',
      'in store',
      'near me',
      'find',
      'buy',
      'where can i get',
    ];
    final normalized = question.toLowerCase();
    return keywords.any(normalized.contains);
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

  String _buildGroqPrompt(
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
    buffer.writeln('Write a concise, friendly, helpful answer as Jasper in normal plain English.');
    buffer.writeln('Do not use Markdown, bullet symbols, headings, bold text, tables, or code formatting.');
    return buffer.toString();
  }

  String _toPlainEnglish(String text) {
    return text
        .replaceAll(RegExp(r'```[^\n]*'), '')
        .replaceAll(RegExp(r'[`*_#>]'), '')
        .replaceAll(RegExp(r'^\s*[-+]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]*\)'), r'\$1')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

}
