import 'package:flutter/foundation.dart';

import '../models/stock_item.dart';
import '../services/firestore_service.dart';

class PharmacyProvider extends ChangeNotifier {
  PharmacyProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  bool isSaving = false;
  String? errorMessage;

  Future<void> saveStock(StockItem stockItem) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _firestoreService.saveStock(stockItem);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setAvailability(String stockId, bool isAvailable) {
    return _firestoreService.updateStockAvailability(stockId, isAvailable);
  }
}
