import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_preferences.dart';
import '../../../../core/services/geocoding_service.dart';

/// Repository for managing user preferences
class SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeocodingService _geocodingService = GeocodingService();
  static const String _tableName = 'user_preferences';

  /// Get user preferences for an alumnus
  Future<UserPreferences?> getUserPreferences(String alumnusId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('alumnus_id', alumnusId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        return await createDefaultPreferences(alumnusId);
      }

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error getting preferences - $error');
      return null;
    }
  }

  /// Create default preferences for an alumnus
  /// Location tracking is enabled by default
  /// Uses upsert to prevent duplicate key errors
  Future<UserPreferences> createDefaultPreferences(String alumnusId) async {
    try {
      print('🔵 SettingsRepository: Creating default preferences for $alumnusId');

      // Use upsert to handle concurrent requests gracefully
      final response = await _supabase
          .from(_tableName)
          .upsert(
            {
              'alumnus_id': alumnusId,
              'location_tracking_enabled': true, // Enabled by default
              'location_tracking_frequency': 'daily',
              'notifications_enabled': true,
            },
            onConflict: 'alumnus_id',
          )
          .select()
          .single();

      print('✅ SettingsRepository: Default preferences created with location tracking enabled');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error creating preferences - $error');
      rethrow;
    }
  }

  /// Update location tracking setting
  Future<UserPreferences> updateLocationTracking(
    String alumnusId,
    bool enabled,
  ) async {
    try {
      print('🔵 SettingsRepository: Updating location tracking to $enabled');

      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'location_tracking_enabled': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      print('✅ SettingsRepository: Location tracking updated');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error updating location tracking - $error');
      rethrow;
    }
  }

  /// Update tracking frequency
  Future<UserPreferences> updateTrackingFrequency(
    String alumnusId,
    String frequency,
  ) async {
    try {
      print('🔵 SettingsRepository: Updating tracking frequency to $frequency');

      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'location_tracking_frequency': frequency,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      print('✅ SettingsRepository: Tracking frequency updated');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error updating frequency - $error');
      rethrow;
    }
  }

  /// Update notifications setting
  Future<UserPreferences> updateNotifications(
    String alumnusId,
    bool enabled,
  ) async {
    try {
      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'notifications_enabled': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error updating notifications - $error');
      rethrow;
    }
  }

  /// Subscribe to preferences changes (realtime)
  Stream<UserPreferences?> subscribeToPreferences(String alumnusId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('alumnus_id', alumnusId)
        .map((data) {
          if (data.isEmpty) return null;
          return UserPreferences.fromSupabaseJson(data.first);
        });
  }

  /// Set manual location override
  ///
  /// [duration] - Duration for the override. If null, it's set forever.
  /// Allowed values: 1 hour, 1 day, 1 week, 1 month, or null (forever)
  Future<UserPreferences> setManualLocation({
    required String alumnusId,
    required String city,
    required String country,
    Duration? duration,
  }) async {
    try {
      print('🔵 SettingsRepository: Setting manual location override');
      print('   - City: $city');
      print('   - Country: $country');
      print('   - Duration: ${duration?.toString() ?? "Forever"}');

      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      // Forward geocode the city to get coordinates
      final coordinates = await _geocodingService.getCoordinatesFromCity(
        city: city,
        country: country,
      );

      if (coordinates == null) {
        throw Exception('Could not find coordinates for "$city, $country". Please check the city name.');
      }

      final latitude = coordinates['latitude']!;
      final longitude = coordinates['longitude']!;

      print('   - Coordinates: ($latitude, $longitude)');

      final expiresAt = duration != null
          ? DateTime.now().add(duration).toIso8601String()
          : null;

      // Update user preferences
      final response = await _supabase
          .from(_tableName)
          .update({
            'manual_location_city': city,
            'manual_location_country': country,
            'manual_location_latitude': null,
            'manual_location_longitude': null,
            'manual_location_expires_at': expiresAt,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      // Delete the old location and insert a new one
      // This ensures created_at gets a fresh timestamp for "last updated" to work correctly
      await _supabase
          .from('locations')
          .delete()
          .eq('alumnus_id', alumnusId)
          .eq('is_current', true);

      // Insert new location with fresh created_at timestamp
      await _supabase
          .from('locations')
          .insert({
            'alumnus_id': alumnusId,
            'city': city,
            'country': country,
            'latitude': latitude,
            'longitude': longitude,
            'location_type': 'manual',
            'is_current': true,
          });

      print('✅ SettingsRepository: Manual location override set (preferences + new location inserted with fresh timestamp)');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error setting manual location - $error');
      rethrow;
    }
  }

  /// Clear manual location override
  /// Resumes automatic GPS tracking
  Future<UserPreferences> clearManualLocation(String alumnusId) async {
    try {
      print('🔵 SettingsRepository: Clearing manual location override');

      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'manual_location_city': null,
            'manual_location_country': null,
            'manual_location_latitude': null,
            'manual_location_longitude': null,
            'manual_location_expires_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      print('✅ SettingsRepository: Manual location override cleared');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error clearing manual location - $error');
      rethrow;
    }
  }

  /// Update visibility on globe setting
  Future<UserPreferences> updateVisibility(
    String alumnusId,
    bool visible,
  ) async {
    try {
      print('🔵 SettingsRepository: Updating visibility to $visible');

      // Ensure preferences exist first
      final existing = await getUserPreferences(alumnusId);
      if (existing == null) {
        throw Exception('Failed to create or get user preferences');
      }

      final response = await _supabase
          .from(_tableName)
          .update({
            'visible_on_globe': visible,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      print('✅ SettingsRepository: Visibility updated');

      return UserPreferences.fromSupabaseJson(response);
    } catch (error) {
      print('❌ SettingsRepository: Error updating visibility - $error');
      rethrow;
    }
  }

  /// Check if manual location has expired and clear if needed
  /// Returns true if expired and was cleared, false otherwise
  Future<bool> checkAndClearExpiredManualLocation(String alumnusId) async {
    try {
      print('🔍 SettingsRepository: Checking manual location expiration for $alumnusId');
      final prefs = await getUserPreferences(alumnusId);
      if (prefs == null) {
        print('   - No preferences found');
        return false;
      }

      // Check if manual location is set
      if (prefs.manualLocationLatitude == null ||
          prefs.manualLocationLongitude == null) {
        print('   - No manual location set');
        return false;
      }

      print('   - Manual location: ${prefs.manualLocationCity}, ${prefs.manualLocationCountry}');

      // Check if it has an expiration time
      if (prefs.manualLocationExpiresAt == null) {
        // No expiration, keep forever
        print('   - No expiration (set forever)');
        return false;
      }

      final now = DateTime.now().toUtc();
      final expiresAt = prefs.manualLocationExpiresAt!.toUtc();
      print('   - Current time (UTC): $now');
      print('   - Expires at (UTC): $expiresAt');
      print('   - Is expired: ${now.isAfter(expiresAt)}');

      // Check if expired
      if (now.isAfter(expiresAt)) {
        print('⏰ SettingsRepository: Manual location expired, clearing...');
        await clearManualLocation(alumnusId);
        print('✅ SettingsRepository: Manual location cleared successfully');
        return true;
      }

      final timeLeft = expiresAt.difference(now);
      print('   - Time remaining: ${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m');
      return false;
    } catch (error) {
      print('❌ SettingsRepository: Error checking expiration - $error');
      return false;
    }
  }

  /// Delete user preferences
  Future<void> deletePreferences(String alumnusId) async {
    try {
      await _supabase.from(_tableName).delete().eq('alumnus_id', alumnusId);
      print('✅ SettingsRepository: Preferences deleted');
    } catch (error) {
      print('❌ SettingsRepository: Error deleting preferences - $error');
      rethrow;
    }
  }
}
