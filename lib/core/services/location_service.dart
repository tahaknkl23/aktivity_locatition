// lib/core/services/location_service.dart - TIMEOUT FIX
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static LocationService? _instance;

  static LocationService get instance {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  LocationService._internal();

  /// Konum izni kontrolü ve alma
  Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.location.status;

      if (permission.isDenied) {
        permission = await Permission.location.request();
      }

      if (permission.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return permission.isGranted;
    } catch (e) {
      debugPrint('[LOCATION] Permission error: $e');
      return false;
    }
  }

  /// Mevcut konumu al - IMPROVED VERSION
  Future<LocationData?> getCurrentLocation() async {
    try {
      // İzin kontrolü
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw 'Konum izni verilmedi';
      }

      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Konum servisleri kapalı. Lütfen GPS\'i açın.';
      }

      debugPrint('[LOCATION] Getting current position...');

      // 🚀 IMPROVED: Progressive location getting
      Position? position;

      try {
        // 1. Önce son bilinen konumu dene (hızlı)
        debugPrint('[LOCATION] Trying last known position...');
        position = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: false,
        );

        if (position != null) {
          // Son konum 5 dakikadan yeniyse kullan
          final age = DateTime.now().difference(position.timestamp);
          if (age.inMinutes <= 5) {
            debugPrint('[LOCATION] Using last known position (${age.inMinutes}min old)');
          } else {
            debugPrint('[LOCATION] Last position too old (${age.inMinutes}min), getting fresh');
            position = null; // Fresh position al
          }
        }
      } catch (e) {
        debugPrint('[LOCATION] Last known position failed: $e');
        position = null;
      }

      // 2. Fresh position al (eğer last known yoksa/eskiyse)
      if (position == null) {
        try {
          debugPrint('[LOCATION] Getting fresh position with medium accuracy...');
          // Önce medium accuracy ile dene (daha hızlı)
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15), // 15 saniye
          );
          debugPrint('[LOCATION] Fresh medium accuracy position obtained');
        } catch (e) {
          debugPrint('[LOCATION] Medium accuracy failed, trying high accuracy: $e');
          // Medium başarısızsa high accuracy dene (daha yavaş ama kesin)
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 45), // 45 saniye
          );
          debugPrint('[LOCATION] High accuracy position obtained');
        }
      }

      debugPrint('[LOCATION] Final position: ${position.latitude}, ${position.longitude}');

      // Adres bilgisini al
      String address = 'Konum alındı';
      try {
        debugPrint('[LOCATION] Getting address from coordinates...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(Duration(seconds: 10)); // Address için 10sn timeout

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = _formatAddress(place);
          debugPrint('[LOCATION] Address obtained: $address');
        }
      } catch (e) {
        debugPrint('[LOCATION] Address lookup failed: $e');
        address = 'Konum: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[LOCATION] Get current location error: $e');

      // User-friendly error messages
      String userMessage = 'Konum alınamadı';

      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        userMessage = 'Konum alma zaman aşımına uğradı. GPS sinyalini kontrol edin ve tekrar deneyin.';
      } else if (e.toString().contains('permission') || e.toString().contains('izin')) {
        userMessage = 'Konum izni gerekli. Lütfen uygulamaya konum iznı verin.';
      } else if (e.toString().contains('service') || e.toString().contains('GPS')) {
        userMessage = 'GPS servisi kapalı. Lütfen cihazınızın GPS ayarını açın.';
      } else if (e.toString().contains('network') || e.toString().contains('internet')) {
        userMessage = 'Konum servisi için internet bağlantısı gerekli.';
      }

      throw userMessage;
    }
  }

  /// Koordinatlardan adres al
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng).timeout(Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }

      return 'Adres bulunamadı';
    } catch (e) {
      debugPrint('[LOCATION] Address lookup error: $e');
      return 'Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  /// Adres formatla
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Bilinmeyen konum';
  }

  /// İki konum arasındaki mesafeyi hesapla (metre)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Mesafe kontrolü - aynı konumda mı?
  bool isAtSameLocation(
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng, {
    double toleranceInMeters = 100, // 100 metre tolerans
  }) {
    double distance = calculateDistance(currentLat, currentLng, targetLat, targetLng);
    debugPrint('[LOCATION] Distance: ${distance.toStringAsFixed(2)} meters (tolerance: $toleranceInMeters)');

    return distance <= toleranceInMeters;
  }

  /// Konum durumu mesajı
  String getLocationStatusMessage(
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng,
  ) {
    double distance = calculateDistance(currentLat, currentLng, targetLat, targetLng);

    if (distance <= 50) {
      return '✅ Firmada bulunuyorsunuz';
    } else if (distance <= 100) {
      return '📍 Firma yakınındasınız (${distance.toStringAsFixed(0)}m)';
    } else if (distance <= 500) {
      return '🚶 Firmaya ${distance.toStringAsFixed(0)} metre mesafede';
    } else if (distance < 1000) {
      return '🚗 Firmaya ${(distance / 1000).toStringAsFixed(1)} km mesafede';
    } else {
      return '🌍 Firmaya ${(distance / 1000).toStringAsFixed(1)} km mesafede';
    }
  }
}

/// Konum verisi modeli - UNCHANGED
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  String get coordinates => '$latitude,$longitude';
  String get displayText => '$address\n$coordinates';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
        timestamp: DateTime.parse(json['timestamp']),
      );

  factory LocationData.fromString(String coordString) {
    try {
      final parts = coordString.split(',');
      if (parts.length == 2) {
        return LocationData(
          latitude: double.parse(parts[0].trim()),
          longitude: double.parse(parts[1].trim()),
          address: 'Seçilen konum',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('[LOCATION] Parse error: $e');
    }

    throw 'Geçersiz koordinat formatı';
  }
}
