import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/background_location_service.dart';
import '../../../../core/services/foreground_location_service.dart';
import '../../../globe/data/repositories/location_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/user_preferences.dart';

part 'settings_provider.g.dart';

// ==================
// SERVICE PROVIDERS
// ==================

/// Settings repository provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Location repository provider (reused from globe feature)
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

/// Background location service provider
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  return BackgroundLocationService();
});

/// Foreground location service provider
final foregroundLocationServiceProvider = Provider<ForegroundLocationService>((ref) {
  return ForegroundLocationService();
});

// ==================
// STATE PROVIDERS
// ==================

/// Settings state provider for an alumnus
@riverpod
class Settings extends _$Settings {
  @override
  Future<UserPreferences?> build(String alumnusId) async {
    return _fetchPreferences(alumnusId);
  }

  Future<UserPreferences?> _fetchPreferences(String alumnusId) async {
    final repo = ref.read(settingsRepositoryProvider);
    return await repo.getUserPreferences(alumnusId);
  }

  /// Toggle location tracking on/off
  Future<void> toggleLocationTracking(bool enabled) async {
    final currentPrefs = await future;
    if (currentPrefs == null) return;

    // Update in Supabase
    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateLocationTracking(currentPrefs.alumnusId, enabled);

    // Enable/disable background service
    final backgroundService = ref.read(backgroundLocationServiceProvider);
    if (enabled) {
      await backgroundService.enable();

      // Save alumnus ID to SharedPreferences for background task
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_alumnus_id', currentPrefs.alumnusId);

      // Start foreground tracking
      final foregroundService = ref.read(foregroundLocationServiceProvider);
      await foregroundService.startTracking();
    } else {
      await backgroundService.disable();

      // Stop foreground tracking
      final foregroundService = ref.read(foregroundLocationServiceProvider);
      foregroundService.stopTracking();
    }

    // Refresh state
    ref.invalidateSelf();
    await future;
  }

  /// Update tracking frequency
  Future<void> updateFrequency(String frequency) async {
    final currentPrefs = await future;
    if (currentPrefs == null) return;

    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateTrackingFrequency(currentPrefs.alumnusId, frequency);

    // Refresh state
    ref.invalidateSelf();
    await future;
  }

  /// Update notifications setting
  Future<void> updateNotifications(bool enabled) async {
    final currentPrefs = await future;
    if (currentPrefs == null) return;

    final repo = ref.read(settingsRepositoryProvider);
    await repo.updateNotifications(currentPrefs.alumnusId, enabled);

    // Refresh state
    ref.invalidateSelf();
    await future;
  }

  /// Refresh settings from database
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Last location update time provider
@riverpod
Future<DateTime?> lastLocationUpdate(Ref ref, String alumnusId) async {
  final locationRepo = ref.read(locationRepositoryProvider);
  return await locationRepo.getLastLocationUpdateTime(alumnusId);
}

/// Foreground tracking status provider
final foregroundTrackingStatusProvider = StateProvider<bool>((ref) => false);
