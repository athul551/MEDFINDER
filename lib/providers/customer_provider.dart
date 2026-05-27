import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/pharmacy.dart';
import '../models/stock_item.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/location_utils.dart';

class StockSearchResult {
  StockSearchResult({
    required this.stock,
    required this.pharmacy,
    this.distanceKm,
  });

  final StockItem stock;
  final Pharmacy pharmacy;
  final double? distanceKm;
}

class CustomerProvider extends ChangeNotifier {
  CustomerProvider({
    FirestoreService? firestoreService,
    LocationService? locationService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _locationService = locationService ?? LocationService();

  final FirestoreService _firestoreService;
  final LocationService _locationService;

  bool isLoading = false;
  String? errorMessage;
  Position? currentPosition;
  List<StockSearchResult> searchResults = [];
  StreamSubscription? _searchSubscription;

  Future<void> loadCurrentLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentPosition = await _locationService.getCurrentPosition();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMedicine(String query) async {
    await _searchSubscription?.cancel();
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _searchSubscription =
        _firestoreService.searchStockByMedicineName(query).listen(
      (items) async {
        final pharmacies = <String, Pharmacy>{};
        for (final item in items) {
          final pharmacy = await _firestoreService.getPharmacy(
            item.pharmacyId,
          );
          if (pharmacy != null) {
            pharmacies[item.pharmacyId] = pharmacy;
          }
        }
        searchResults = items
            .where((item) => pharmacies.containsKey(item.pharmacyId))
            .map((item) {
          final pharmacy = pharmacies[item.pharmacyId]!;
          final position = currentPosition;
          final distance = position == null
              ? null
              : LocationUtils.distanceInKm(
                  startLatitude: position.latitude,
                  startLongitude: position.longitude,
                  endLatitude: pharmacy.latitude,
                  endLongitude: pharmacy.longitude,
                );
          return StockSearchResult(
            stock: item,
            pharmacy: pharmacy,
            distanceKm: distance,
          );
        }).toList()
          ..sort((a, b) {
            final first = a.distanceKm ?? double.maxFinite;
            final second = b.distanceKm ?? double.maxFinite;
            return first.compareTo(second);
          });
        isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = error.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    super.dispose();
  }
}
