import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

/// Represents a fair/exhibition location with metadata.
class Fair {
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final int points;

  const Fair({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.points,
  });
}

class LocationService {
  /// Predefined fair locations.
  static const List<Fair> fairs = [
    Fair(
      name: 'Education Fair',
      latitude: 1.53123,
      longitude: 103.67890,
      radius: 500,
      points: 10,
    ),
    Fair(
      name: 'Job Fair',
      latitude: 1.55750,
      longitude: 103.71234,
      radius: 300,
      points: 15,
    ),
    Fair(
      name: 'Career Exhibition',
      latitude: 1.48350,
      longitude: 103.76120,
      radius: 400,
      points: 20,
    ),
  ];

  double calculateDistance(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Returns the nearest fair and the distance (in meters) to it.
  ({Fair fair, double distance}) getNearestFair(
      double userLat, double userLng) {
    Fair nearest = fairs.first;
    double minDistance = calculateDistance(
        userLat, userLng, nearest.latitude, nearest.longitude);

    for (final fair in fairs.skip(1)) {
      final d =
          calculateDistance(userLat, userLng, fair.latitude, fair.longitude);
      if (d < minDistance) {
        minDistance = d;
        nearest = fair;
      }
    }

    return (fair: nearest, distance: minDistance);
  }

  /// STEP 1: Check and request permission
  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
  }

  /// STEP 2: Get current position
  Future<Position> getCurrentLocation() async {
    await _checkPermission();

    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// STEP 3: Convert coordinates → readable address
  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      // Validate coordinates
      if (position.latitude == 0 && position.longitude == 0) {
        return "Invalid coordinates";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      // Build readable address
      final formattedAddress = _formatAddress(place);
      if (formattedAddress.isEmpty) {
        return _buildCoordinateFallback(position);
      }
      return formattedAddress;
    } on NoResultFoundException {
      return _buildCoordinateFallback(position);
    } on PlatformException catch (e) {
      final message = (e.message ?? 'geocoding service error').toLowerCase();
      if (message.contains('unexpected null value')) {
        return _buildCoordinateFallback(position);
      }
      return 'Address unavailable: ${e.message ?? 'geocoding service error'}';
    } on TimeoutException {
      return _buildCoordinateFallback(position);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('unexpected null value')) {
        return _buildCoordinateFallback(position);
      }
      return 'Address unavailable: $e';
    }
  }

  /// STEP 4: Format address (clean output)
  String _formatAddress(Placemark place) {
    final parts = [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country,
    ];

    return parts
      .map((e) => (e ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .join(', ');
  }

  String _buildCoordinateFallback(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, '
        'Lng: ${position.longitude.toStringAsFixed(6)}';
  }

  /// STEP 5: Combined method (optional helper)
  Future<Map<String, dynamic>> getFullLocationData() async {
    final position = await getCurrentLocation();

    final address = await getAddressFromCoordinates(position);

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
    };
  }
}