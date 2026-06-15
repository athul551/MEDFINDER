import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/pharmacy.dart';
import '../utils/app_constants.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirestoreService? firestoreService})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AppUser?> currentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final appUser = await _firestoreService.getUser(user.uid);
    if (appUser != null) return appUser;
    if (user.isAnonymous) {
      return _createGuestProfile(user);
    }
    await _auth.signOut();
    return null;
  }

  Future<AppUser> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _createAccount(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: UserRole.customer,
    );
  }

  Future<AppUser> registerPharmacyOwner({
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required String pharmacyName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final user = await _createAccount(
      name: ownerName,
      email: email,
      phone: phone,
      password: password,
      role: UserRole.pharmacyOwner,
    );
    final pharmacy = Pharmacy(
      pharmacyId: '',
      ownerId: user.uid,
      name: pharmacyName,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      isVerified: true,
      createdAt: DateTime.now(),
    );
    await _firestoreService.createPharmacy(pharmacy);
    return user;
  }

  Future<AppUser> _createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user!;
    await firebaseUser.updateDisplayName(name.trim());
    await firebaseUser.getIdToken(true);
    final appUser = AppUser(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await _firestoreService.createUser(appUser);
    return appUser;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final appUser = await _firestoreService.getUser(credential.user!.uid);
    if (appUser == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'missing-user-profile',
        message: 'No app profile exists for this account.',
      );
    }
    return appUser;
  }

  Future<AppUser> signInAsGuest() async {
    final credential = await _auth.signInAnonymously();
    return _createGuestProfile(credential.user!);
  }

  Future<AppUser> _createGuestProfile(User firebaseUser) async {
    final existingUser = await _firestoreService.getUser(firebaseUser.uid);
    if (existingUser != null) return existingUser;

    final appUser = AppUser(
      uid: firebaseUser.uid,
      name: 'Guest User',
      email: '',
      phone: '',
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    await _firestoreService.createUser(appUser);
    return appUser;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> deleteUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser?.uid != userId) {
      await _deleteFirestoreAccountData(userId);
      return;
    }

    await _deleteFirestoreAccountData(userId);

    try {
      await currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Your session has expired. Please sign in again and try '
              'deleting your account.',
        );
      }
      rethrow;
    }
  }

  Future<void> _deleteFirestoreAccountData(String userId) async {
    final pharmacy = await _firestoreService.getPharmacyByOwnerId(userId);
    if (pharmacy != null) {
      await _firestoreService.deletePharmacy(pharmacy.pharmacyId);
    }

    await _firestoreService.deleteUser(userId);
  }

  Future<void> signOut() => _auth.signOut();
}
