import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/medicine.dart';
import '../models/pharmacy.dart';
import '../models/pharmacy_review.dart';
import '../models/reservation.dart';
import '../models/stock_item.dart';
import '../utils/app_constants.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const _batchDeleteLimit = 450;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppCollections.users);
  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _db.collection(AppCollections.pharmacies);
  CollectionReference<Map<String, dynamic>> get _medicines =>
      _db.collection(AppCollections.medicines);
  CollectionReference<Map<String, dynamic>> get _stock =>
      _db.collection(AppCollections.stock);
  CollectionReference<Map<String, dynamic>> get _reservations =>
      _db.collection(AppCollections.reservations);
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(AppCollections.notifications);
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(AppCollections.reviews);

  Future<void> createUser(AppUser user) {
    return _users.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(snapshot.data()!);
  }

  Future<void> updateUserProfileImage(String userId, String imageUrl) {
    return _users.doc(userId).update({'profileImageUrl': imageUrl});
  }

  Future<void> deleteUser(String userId) async {
    final references = <DocumentReference<Map<String, dynamic>>>[
      _users.doc(userId),
    ];

    // Delete all notifications for this user
    final notifications =
        await _notifications.where('userId', isEqualTo: userId).get();
    for (final doc in notifications.docs) {
      references.add(doc.reference);
    }

    // Delete all reservations for this user
    final reservations =
        await _reservations.where('userId', isEqualTo: userId).get();
    for (final doc in reservations.docs) {
      references.add(doc.reference);
    }

    // Delete all reviews by this user
    final reviews = await _reviews.where('userId', isEqualTo: userId).get();
    for (final doc in reviews.docs) {
      references.add(doc.reference);
    }

    await _deleteDocumentReferences(references);
  }

  Stream<List<AppUser>> watchUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList(),
        );
  }

  Future<String> createPharmacy(Pharmacy pharmacy) async {
    final doc = _pharmacies.doc();
    final newPharmacy = Pharmacy(
      pharmacyId: doc.id,
      ownerId: pharmacy.ownerId,
      name: pharmacy.name,
      address: pharmacy.address,
      phone: pharmacy.phone,
      latitude: pharmacy.latitude,
      longitude: pharmacy.longitude,
      isVerified: pharmacy.isVerified,
      createdAt: pharmacy.createdAt,
    );
    await doc.set(newPharmacy.toMap());
    return doc.id;
  }

  Future<void> updatePharmacy(Pharmacy pharmacy) {
    return _pharmacies.doc(pharmacy.pharmacyId).update(pharmacy.toMap());
  }

  Future<void> verifyPharmacy(String pharmacyId, bool isVerified) {
    return _pharmacies.doc(pharmacyId).update({'isVerified': isVerified});
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    final references = <DocumentReference<Map<String, dynamic>>>[
      _pharmacies.doc(pharmacyId),
    ];

    // Delete all stock items for this pharmacy
    final stock = await _stock.where('pharmacyId', isEqualTo: pharmacyId).get();
    for (final doc in stock.docs) {
      references.add(doc.reference);
    }

    // Delete all reservations for this pharmacy
    final reservations =
        await _reservations.where('pharmacyId', isEqualTo: pharmacyId).get();
    for (final doc in reservations.docs) {
      references.add(doc.reference);
    }

    // Delete all reviews for this pharmacy
    final reviews =
        await _reviews.where('pharmacyId', isEqualTo: pharmacyId).get();
    for (final doc in reviews.docs) {
      references.add(doc.reference);
    }

    await _deleteDocumentReferences(references);
  }

  Stream<List<Pharmacy>> watchVerifiedPharmacies() {
    return _pharmacies.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Pharmacy.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<Pharmacy>> watchAllPharmacies() {
    return _pharmacies.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Pharmacy.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<Pharmacy?> getPharmacy(String pharmacyId) async {
    final doc = await _pharmacies.doc(pharmacyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Pharmacy.fromMap(doc.data()!, id: doc.id);
  }

  Stream<Pharmacy?> watchPharmacyById(String pharmacyId) {
    return _pharmacies.doc(pharmacyId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Pharmacy.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  Future<Pharmacy?> getPharmacyByOwnerId(String ownerId) async {
    final snapshot =
        await _pharmacies.where('ownerId', isEqualTo: ownerId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Pharmacy.fromMap(doc.data(), id: doc.id);
  }

  Stream<Pharmacy?> watchPharmacyForOwner(String ownerId) {
    return _pharmacies
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Pharmacy.fromMap(doc.data(), id: doc.id);
    });
  }

  Future<String> saveMedicine(Medicine medicine) async {
    final doc = medicine.medicineId.isEmpty
        ? _medicines.doc()
        : _medicines.doc(medicine.medicineId);
    final saved = Medicine(
      medicineId: doc.id,
      name: medicine.name,
      category: medicine.category,
      description: medicine.description,
    );
    await doc.set(saved.toMap(), SetOptions(merge: true));
    return doc.id;
  }

  Stream<List<Medicine>> watchMedicines() {
    return _medicines.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Medicine.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<List<Medicine>> searchMedicinesByFreeText(String query) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _medicines.orderBy('name').get();
    return snapshot.docs
        .map((doc) => Medicine.fromMap(doc.data(), id: doc.id))
        .where((medicine) =>
            normalized.contains(medicine.name.toLowerCase()) ||
            normalized.contains(medicine.category.toLowerCase()))
        .toList();
  }

  Future<List<Pharmacy>> getPharmaciesByIds(List<String> pharmacyIds) async {
    if (pharmacyIds.isEmpty) return [];
    final futures = pharmacyIds.map((id) => _pharmacies.doc(id).get());
    final docs = await Future.wait(futures);
    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => Pharmacy.fromMap(doc.data()!, id: doc.id))
        .toList();
  }

  Future<String> saveStock(StockItem stockItem) async {
    final doc = stockItem.stockId.isEmpty
        ? _stock.doc()
        : _stock.doc(stockItem.stockId);
    final saved = StockItem(
      stockId: doc.id,
      pharmacyId: stockItem.pharmacyId,
      medicineId: stockItem.medicineId,
      medicineName: stockItem.medicineName,
      quantity: stockItem.quantity,
      price: stockItem.price,
      expiryDate: stockItem.expiryDate,
      isAvailable: stockItem.isAvailable,
      updatedAt: DateTime.now(),
    );
    await doc.set(saved.toMap(), SetOptions(merge: true));
    return doc.id;
  }

  Future<void> updateStockAvailability(String stockId, bool isAvailable) {
    return _stock.doc(stockId).update({
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<StockItem>> watchStockForPharmacy(String pharmacyId) {
    return _stock
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final stock = snapshot.docs
          .map((doc) => StockItem.fromMap(doc.data(), id: doc.id))
          .toList();
      stock.sort((a, b) => a.medicineName.compareTo(b.medicineName));
      return stock;
    });
  }

  Stream<List<StockItem>> searchStockByMedicineName(String query) {
    final normalized = query.trim().toLowerCase();
    return _stock.orderBy('medicineName').snapshots().asyncMap((snapshot) {
      final stockItems = snapshot.docs
          .map((doc) => StockItem.fromMap(doc.data(), id: doc.id))
          .where(
            (stock) =>
                stock.medicineName.toLowerCase().contains(normalized) &&
                stock.isAvailable,
          )
          .toList();
      return _filterStockForVisiblePharmacies(stockItems);
    });
  }

  Future<List<StockItem>> searchStockByMedicineNameOnce(String query) async {
    final normalized = query.trim().toLowerCase();
    final snapshot = await _stock.orderBy('medicineName').get();
    final stockItems = snapshot.docs
        .map((doc) => StockItem.fromMap(doc.data(), id: doc.id))
        .where(
          (stock) =>
              stock.medicineName.toLowerCase().contains(normalized) &&
              stock.isAvailable,
        )
        .toList();
    return _filterStockForVisiblePharmacies(stockItems);
  }

  Future<List<StockItem>> _filterStockForVisiblePharmacies(
    List<StockItem> stockItems,
  ) async {
    if (stockItems.isEmpty) return [];

    final pharmacyIds = stockItems
        .map((stock) => stock.pharmacyId)
        .where((pharmacyId) => pharmacyId.isNotEmpty)
        .toSet()
        .toList();
    final pharmacies = await getPharmaciesByIds(pharmacyIds);
    final visiblePharmacyIds = pharmacies
        .where((pharmacy) => pharmacy.isVerified)
        .map((pharmacy) => pharmacy.pharmacyId)
        .toSet();

    return stockItems
        .where((stock) => visiblePharmacyIds.contains(stock.pharmacyId))
        .toList();
  }

  Future<void> _deleteDocumentReferences(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    for (var start = 0; start < references.length; start += _batchDeleteLimit) {
      final batch = _db.batch();
      final chunk = references.skip(start).take(_batchDeleteLimit);
      for (final reference in chunk) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  Future<String> createReservation(Reservation reservation) async {
    final doc = _reservations.doc();
    final saved = Reservation(
      reservationId: doc.id,
      userId: reservation.userId,
      pharmacyId: reservation.pharmacyId,
      medicineId: reservation.medicineId,
      medicineName: reservation.medicineName,
      pharmacyName: reservation.pharmacyName,
      quantity: reservation.quantity,
      status: reservation.status,
      reservedAt: DateTime.now(),
      pickupTime: reservation.pickupTime,
      prescriptionUrl: reservation.prescriptionUrl,
    );
    await doc.set(saved.toMap());
    await createNotification(
      userId: reservation.userId,
      title: 'Reservation created',
      message:
          '${reservation.medicineName} was reserved at ${reservation.pharmacyName}.',
    );
    return doc.id;
  }

  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus status,
  ) async {
    final reservationRef = _reservations.doc(reservationId);

    await _db.runTransaction((tx) async {
      final resSnap = await tx.get(reservationRef);
      if (!resSnap.exists || resSnap.data() == null) {
        throw Exception('Reservation not found');
      }
      final reservation =
          Reservation.fromMap(resSnap.data()!, id: reservationId);

      // update reservation status
      tx.update(reservationRef, {'status': status.name});

      // if picked up, decrement corresponding stock quantity
      if (status == ReservationStatus.pickedUp) {
        final stockQuery = await _stock
            .where('pharmacyId', isEqualTo: reservation.pharmacyId)
            .where('medicineId', isEqualTo: reservation.medicineId)
            .limit(1)
            .get();
        if (stockQuery.docs.isNotEmpty) {
          final stockDoc = stockQuery.docs.first;
          final data = stockDoc.data();
          final currentQty = (data['quantity'] as num?)?.toInt() ?? 0;
          final newQty = (currentQty - reservation.quantity) < 0
              ? 0
              : (currentQty - reservation.quantity);
          final isAvailable = newQty > 0;
          tx.update(stockDoc.reference, {
            'quantity': newQty,
            'isAvailable': isAvailable,
            'updatedAt': Timestamp.now(),
          });
        }
      }
    });
  }

  Stream<List<Reservation>> watchReservationsForUser(String userId) {
    return _reservations
        .where('userId', isEqualTo: userId)
        .orderBy('reservedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<Reservation>> watchReservationsForPharmacy(String pharmacyId) {
    return _reservations
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
      final reservations = snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), id: doc.id))
          .toList();
      reservations.sort((a, b) => b.reservedAt.compareTo(a.reservedAt));
      return reservations;
    });
  }

  Stream<List<Reservation>> watchAllReservations() {
    return _reservations
        .orderBy('reservedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reservation.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
  }) {
    final doc = _notifications.doc();
    final notification = AppNotification(
      notificationId: doc.id,
      userId: userId,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
    );
    return doc.set(notification.toMap());
  }

  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<PharmacyReview>> watchReviewsForPharmacy(String pharmacyId) {
    return _reviews
        .where('pharmacyId', isEqualTo: pharmacyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PharmacyReview.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<bool> hasExistingReview({
    required String userId,
    required String pharmacyId,
    required ReviewTrigger triggerType,
    String? reservationId,
  }) async {
    Query<Map<String, dynamic>> query = _reviews
        .where('userId', isEqualTo: userId)
        .where('pharmacyId', isEqualTo: pharmacyId)
        .where('triggerType', isEqualTo: triggerType.value);

    if (reservationId != null) {
      query = query.where('reservationId', isEqualTo: reservationId);
    }

    final snapshot = await query.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> canReviewPharmacy({
    required String userId,
    required String pharmacyId,
    required ReviewTrigger triggerType,
    String? reservationId,
  }) async {
    if (await hasExistingReview(
      userId: userId,
      pharmacyId: pharmacyId,
      triggerType: triggerType,
      reservationId: reservationId,
    )) {
      return false;
    }

    final reservations = await _reservations
        .where('userId', isEqualTo: userId)
        .where('pharmacyId', isEqualTo: pharmacyId)
        .get();

    if (reservations.docs.isEmpty) return false;

    final userReservations = reservations.docs
        .map((doc) => Reservation.fromMap(doc.data(), id: doc.id))
        .toList();

    switch (triggerType) {
      case ReviewTrigger.reservation:
        if (reservationId == null) return false;
        return userReservations.any(
          (reservation) =>
              reservation.reservationId == reservationId &&
              reservation.status != ReservationStatus.rejected &&
              reservation.status != ReservationStatus.cancelled,
        );
      case ReviewTrigger.purchase:
        if (reservationId == null) return false;
        return userReservations.any(
          (reservation) =>
              reservation.reservationId == reservationId &&
              reservation.status == ReservationStatus.pickedUp,
        );
      case ReviewTrigger.visit:
        return userReservations.any(
          (reservation) =>
              reservation.status == ReservationStatus.approved ||
              reservation.status == ReservationStatus.pickedUp,
        );
    }
  }

  Future<String> createReview(PharmacyReview review) async {
    final canReview = await canReviewPharmacy(
      userId: review.userId,
      pharmacyId: review.pharmacyId,
      triggerType: review.triggerType,
      reservationId: review.reservationId,
    );
    if (!canReview) {
      throw Exception('You are not eligible to submit this review.');
    }

    final doc = _reviews.doc();
    final saved = PharmacyReview(
      reviewId: doc.id,
      pharmacyId: review.pharmacyId,
      pharmacyName: review.pharmacyName,
      userId: review.userId,
      userName: review.userName,
      triggerType: review.triggerType,
      reservationId: review.reservationId,
      overallRating: review.overallRating,
      availabilityRating: review.availabilityRating,
      pricingRating: review.pricingRating,
      serviceRating: review.serviceRating,
      deliveryRating: review.deliveryRating,
      comment: review.comment,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      final pharmacyRef = _pharmacies.doc(review.pharmacyId);
      final pharmacySnap = await tx.get(pharmacyRef);
      if (!pharmacySnap.exists || pharmacySnap.data() == null) {
        throw Exception('Pharmacy not found');
      }

      final pharmacy = Pharmacy.fromMap(
        pharmacySnap.data()!,
        id: review.pharmacyId,
      );
      final newCount = pharmacy.reviewCount + 1;
      final newAverage = ((pharmacy.averageRating * pharmacy.reviewCount) +
              saved.overallRating) /
          newCount;
      final newAvailability = ((pharmacy.availabilityAvg * pharmacy.reviewCount) +
              saved.availabilityRating) /
          newCount;
      final newPricing = ((pharmacy.pricingAvg * pharmacy.reviewCount) +
              saved.pricingRating) /
          newCount;
      final newService = ((pharmacy.serviceAvg * pharmacy.reviewCount) +
              saved.serviceRating) /
          newCount;
      final newDelivery = ((pharmacy.deliveryAvg * pharmacy.reviewCount) +
              saved.deliveryRating) /
          newCount;

      tx.set(doc, saved.toMap());
      tx.update(pharmacyRef, {
        'averageRating': double.parse(newAverage.toStringAsFixed(1)),
        'reviewCount': newCount,
        'availabilityAvg': double.parse(newAvailability.toStringAsFixed(1)),
        'pricingAvg': double.parse(newPricing.toStringAsFixed(1)),
        'serviceAvg': double.parse(newService.toStringAsFixed(1)),
        'deliveryAvg': double.parse(newDelivery.toStringAsFixed(1)),
      });
    });

    return doc.id;
  }
}
