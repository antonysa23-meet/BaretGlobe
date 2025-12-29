import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/globe/data/repositories/location_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import 'geocoding_service.dart';

/// Service for tracking location in real-time when app is in foreground
class ForegroundLocationService {
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  final LocationRepository _locationRepository = LocationRepository();
  final GeocodingService _geocodingService = GeocodingService();
  final SettingsRepository _settingsRepository = SettingsRepository();

  static const Duration _updateInterval = Duration(minutes: 5);
  static const double _minimumDistanceMeters = 1000; // 1km

  /// Start tracking location in foreground
  Future<void> startTracking() async {
    try {
      print('🔵 ForegroundLocationService: Starting foreground tracking...');

      // Check if already tracking
      if (_positionStream != null) {
        print('⚠️ ForegroundLocationService: Already tracking');
        return;
      }

      // Get current position first
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _lastPosition = initialPosition;

      // Immediately update database with initial position
      print('📍 ForegroundLocationService: Got initial position, updating database immediately...');
      await _updateLocationInDatabase(initialPosition);

      // Start position stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // Update every 100 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          print('❌ ForegroundLocationService: Stream error - $error');
        },
        cancelOnError: false,
      );

      print('✅ ForegroundLocationService: Tracking started');
    } catch (error) {
      print('❌ ForegroundLocationService: Error starting tracking - $error');
    }
  }

  /// Stop tracking location
  void stopTracking() {
    print('🔵 ForegroundLocationService: Stopping foreground tracking...');

    _positionStream?.cancel();
    _positionStream = null;

    _updateTimer?.cancel();
    _updateTimer = null;

    print('✅ ForegroundLocationService: Tracking stopped');
  }

  /// Handle position updates from stream
  void _onPositionUpdate(Position position) {
    print('📍 ForegroundLocationService: Position update: ${position.latitude}, ${position.longitude}');

    // Check if we should update the database
    if (_shouldUpdateDatabase(position)) {
      _updateLocationInDatabase(position);
    }
  }

  /// Check if we should update the database
  bool _shouldUpdateDatabase(Position position) {
    // Check time interval
    if (_lastUpdateTime != null) {
      final elapsed = DateTime.now().difference(_lastUpdateTime!);
      if (elapsed < _updateInterval) {
        print('⏰ ForegroundLocationService: Skipping update - too soon (${elapsed.inMinutes}m < ${_updateInterval.inMinutes}m)');
        return false;
      }
    }

    // Check distance moved
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < _minimumDistanceMeters) {
        print('📏 ForegroundLocationService: Skipping update - distance too small (${distance.toStringAsFixed(0)}m < ${_minimumDistanceMeters}m)');
        return false;
      }
    }

    return true;
  }

  /// Update location in database
  Future<void> _updateLocationInDatabase(Position position) async {
    try {
      print('💾 ForegroundLocationService: Updating location in database...');

      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ ForegroundLocationService: No authenticated user');
        return;
      }

      // Get alumnus profile
      final alumnus = await _locationRepository.getAlumnusByAuthUserId(user.id);
      if (alumnus == null) {
        print('❌ ForegroundLocationService: No alumnus profile found');
        return;
      }

      // Check for manual location override
      final prefs = await _settingsRepository.getUserPreferences(alumnus.id);
      if (prefs != null &&
          prefs.manualLocationLatitude != null &&
          prefs.manualLocationLongitude != null) {

        // Check if expired
        final expired = await _settingsRepository.checkAndClearExpiredManualLocation(alumnus.id);

        if (!expired) {
          // Manual location is active and not expired - skip GPS update
          print('⏸️ ForegroundLocationService: Manual location override active - skipping GPS update');
          print('   - Manual location: ${prefs.manualLocationCity}, ${prefs.manualLocationCountry}');

          if (prefs.manualLocationExpiresAt != null) {
            final timeLeft = prefs.manualLocationExpiresAt!.difference(DateTime.now());
            print('   - Expires in: ${timeLeft.inHours} hours');
          } else {
            print('   - Set forever');
          }
          return;
        } else {
          print('⏰ ForegroundLocationService: Manual location expired - resuming GPS tracking');
        }
      }

      // Geocode to city
      final city = await _geocodingService.approximateToNearestCity(
        position.latitude,
        position.longitude,
      );

      // Get country
      final country = await _geocodingService.getCountry(
        position.latitude,
        position.longitude,
      );

      // Update location
      await _locationRepository.updateLocationWithFunction(
        alumnusId: alumnus.id,
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country ?? 'Unknown',
        locationType: 'background', // Use 'background' type for automatic updates
        notes: 'Automatic foreground update',
      );

      // Update tracking state
      _lastPosition = position;
      _lastUpdateTime = DateTime.now();

      print('✅ ForegroundLocationService: Location updated successfully');
    } catch (error) {
      print('❌ ForegroundLocationService: Error updating location - $error');
    }
  }

  /// Check if currently tracking
  bool get isTracking => _positionStream != null;

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  /// Get last update time
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Dispose of resources
  void dispose() {
    stopTracking();
  }
}
