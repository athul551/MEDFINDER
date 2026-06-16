import 'package:flutter/foundation.dart';

import '../models/medicine_subscription.dart';
import '../services/firestore_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  bool isSaving = false;
  String? errorMessage;

  Future<String> createSubscription(MedicineSubscription sub) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await _firestoreService.createSubscription(sub);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateSubscription(MedicineSubscription sub) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _firestoreService.updateSubscription(sub);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _firestoreService.deleteSubscription(subscriptionId);
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> refillNow(MedicineSubscription sub) async {
    final now = DateTime.now();
    final nextRefill = DateTime(
      now.year,
      now.month,
      now.day + sub.frequencyDays,
    );
    final updated = sub.copyWith(
      lastRefillDate: now,
      nextRefillDate: nextRefill,
    );
    await updateSubscription(updated);
  }

  Future<void> toggleActive(MedicineSubscription sub) async {
    final updated = sub.copyWith(isActive: !sub.isActive);
    await updateSubscription(updated);
  }
}
