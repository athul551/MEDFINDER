import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class HuntRouteStop {
  HuntRouteStop({
    required this.pharmacy,
    required this.medicines,
    this.distanceKm,
  });

  final Pharmacy pharmacy;
  final List<String> medicines;
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
  bool isHuntLoading = false;
  String? errorMessage;
  String? huntErrorMessage;
  Position? currentPosition;
  List<StockSearchResult> searchResults = [];
  List<HuntRouteStop> huntRoute = [];
  StreamSubscription? _searchSubscription;

  List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    notifyListeners();
    _saveRecentSearches();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList('recent_searches') ?? [];
    notifyListeners();
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
    _saveRecentSearches();
  }

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
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      addRecentSearch(trimmed);
    }
    await _searchSubscription?.cancel();
    if (trimmed.isEmpty) {
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

  Future<void> buildMedicineHuntRoute(String query) async {
    huntRoute = [];
    huntErrorMessage = null;
    final medicines = query
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (medicines.isEmpty) {
      huntErrorMessage = 'Enter at least one medicine name.';
      notifyListeners();
      return;
    }

    isHuntLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (currentPosition == null) {
        await loadCurrentLocation();
      }

      final pharmacyCache = <String, Pharmacy>{};
      final routeMap = <String, HuntRouteStop>{};
      final unavailable = <String>[];

      for (final medicine in medicines) {
        final stocks = await _firestoreService
            .searchStockByMedicineNameOnce(medicine);

        if (stocks.isEmpty) {
          unavailable.add(medicine);
          continue;
        }

        StockSearchResult? bestResult;
        for (final stock in stocks) {
          final pharmacy = pharmacyCache[stock.pharmacyId] ??
              await _firestoreService.getPharmacy(stock.pharmacyId);
          if (pharmacy == null) continue;
          pharmacyCache[stock.pharmacyId] = pharmacy;

          final distance = currentPosition == null
              ? null
              : LocationUtils.distanceInKm(
                  startLatitude: currentPosition!.latitude,
                  startLongitude: currentPosition!.longitude,
                  endLatitude: pharmacy.latitude,
                  endLongitude: pharmacy.longitude,
                );

          final result = StockSearchResult(
            stock: stock,
            pharmacy: pharmacy,
            distanceKm: distance,
          );

          if (bestResult == null ||
              (result.distanceKm ?? double.maxFinite) <
                  (bestResult.distanceKm ?? double.maxFinite)) {
            bestResult = result;
          }
        }

        if (bestResult == null) {
          unavailable.add(medicine);
          continue;
        }

        final chosen = bestResult;
        final key = chosen.pharmacy.pharmacyId;
        routeMap.update(
          key,
          (existing) {
            final medicines = [...existing.medicines, chosen.stock.medicineName];
            medicines.sort();
            return HuntRouteStop(
              pharmacy: existing.pharmacy,
              medicines: medicines,
              distanceKm: existing.distanceKm ?? chosen.distanceKm,
            );
          },
          ifAbsent: () => HuntRouteStop(
            pharmacy: chosen.pharmacy,
            medicines: [chosen.stock.medicineName],
            distanceKm: chosen.distanceKm,
          ),
        );
      }

      final stops = routeMap.values.toList();
      if (currentPosition != null && stops.isNotEmpty) {
        final orderedStops = <HuntRouteStop>[];
        var currentLat = currentPosition!.latitude;
        var currentLng = currentPosition!.longitude;

        while (stops.isNotEmpty) {
          stops.sort((a, b) {
            final distA = LocationUtils.distanceInKm(
              startLatitude: currentLat,
              startLongitude: currentLng,
              endLatitude: a.pharmacy.latitude,
              endLongitude: a.pharmacy.longitude,
            );
            final distB = LocationUtils.distanceInKm(
              startLatitude: currentLat,
              startLongitude: currentLng,
              endLatitude: b.pharmacy.latitude,
              endLongitude: b.pharmacy.longitude,
            );
            return distA.compareTo(distB);
          });
          final nextStop = stops.removeAt(0);
          orderedStops.add(nextStop);
          currentLat = nextStop.pharmacy.latitude;
          currentLng = nextStop.pharmacy.longitude;
        }
        huntRoute = orderedStops;
      } else {
        huntRoute = stops;
      }

      if (unavailable.isNotEmpty) {
        huntErrorMessage =
            'No stock found for: ${unavailable.join(', ')}.';
      }
    } catch (error) {
      huntErrorMessage = error.toString();
    } finally {
      isHuntLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    super.dispose();
  }
}
