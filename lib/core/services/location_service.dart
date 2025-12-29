import 'package:geolocator/geolocator.dart';

/// Service for handling device location
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position
  ///
  /// Returns null if permission is denied or location services are disabled
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        print('❌ LocationService: Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ LocationService: Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ LocationService: Location permission permanently denied');
        return null;
      }

      print('🔵 LocationService: Getting current position...');

      // Get position with medium accuracy (good balance between accuracy and battery)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ LocationService: Got position: ${position.latitude}, ${position.longitude}');

      return position;
    } catch (error) {
      print('❌ LocationService: Error getting position - $error');
      return null;
    }
  }

  /// Get last known position (faster, uses cached location)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (error) {
      print('❌ LocationService: Error getting last position - $error');
      return null;
    }
  }

  /// Open app settings (for when permission is permanently denied)
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
