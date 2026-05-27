import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({AuthService? authService, FirestoreService? firestoreService})
      : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService();

  final AuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription? _authSubscription;

  AppUser? appUser;
  bool isLoading = true;
  String? errorMessage;

  bool get isSignedIn => appUser != null;
  UserRole? get role => appUser?.role;

  void start() {
    _authSubscription ??= _authService.authStateChanges.listen((user) async {
      isLoading = true;
      notifyListeners();
      try {
        appUser = user == null ? null : await _authService.currentAppUser();
        errorMessage = null;
      } catch (error) {
        errorMessage = error.toString();
      } finally {
        isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    await _run(() async {
      appUser = await _authService.signIn(email: email, password: password);
    });
  }

  Future<void> signInAsGuest() async {
    await _run(() async {
      appUser = await _authService.signInAsGuest();
    });
  }

  Future<void> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _run(() async {
      appUser = await _authService.registerCustomer(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    });
  }

  Future<void> registerPharmacyOwner({
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required String pharmacyName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _run(() async {
      appUser = await _authService.registerPharmacyOwner(
        ownerName: ownerName,
        email: email,
        phone: phone,
        password: password,
        pharmacyName: pharmacyName,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    appUser = null;
    notifyListeners();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    if (appUser == null) return;
    await _firestoreService.updateUserProfileImage(appUser!.uid, imageUrl);
    appUser = appUser!.copyWith(profileImageUrl: imageUrl);
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
