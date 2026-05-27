import 'package:flutter/foundation.dart';

import '../models/medicine.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  bool isSaving = false;

  Future<void> verifyPharmacy(String pharmacyId, bool isVerified) {
    return _firestoreService.verifyPharmacy(pharmacyId, isVerified);
  }

  Future<void> removePharmacy(String pharmacyId) {
    return _firestoreService.deletePharmacy(pharmacyId);
  }

  Future<void> saveMedicineCategory({
    required String name,
    required String category,
    required String description,
  }) async {
    isSaving = true;
    notifyListeners();
    try {
      await _firestoreService.saveMedicine(
        Medicine(
          medicineId: '',
          name: name,
          category: category,
          description: description,
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
