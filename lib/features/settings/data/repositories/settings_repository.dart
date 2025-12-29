import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_preferences.dart';

/// Repository for managing user preferences
class SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
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
  Future<UserPreferences> createDefaultPreferences(String alumnusId) async {
    try {
      print('🔵 SettingsRepository: Creating default preferences for $alumnusId');

      final response = await _supabase.from(_tableName).insert({
        'alumnus_id': alumnusId,
        'location_tracking_enabled': true, // Enabled by default
        'location_tracking_frequency': 'daily',
        'notifications_enabled': true,
      }).select().single();

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
    required double latitude,
    required double longitude,
    required String city,
    required String country,
    Duration? duration,
  }) async {
    try {
      print('🔵 SettingsRepository: Setting manual location override');
      print('   - City: $city');
      print('   - Country: $country');
      print('   - Coords: ($latitude, $longitude)');
      print('   - Duration: ${duration?.toString() ?? "Forever"}');

      final expiresAt = duration != null
          ? DateTime.now().add(duration).toIso8601String()
          : null;

      final response = await _supabase
          .from(_tableName)
          .update({
            'manual_location_city': city,
            'manual_location_country': country,
            'manual_location_latitude': latitude,
            'manual_location_longitude': longitude,
            'manual_location_expires_at': expiresAt,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('alumnus_id', alumnusId)
          .select()
          .single();

      print('✅ SettingsRepository: Manual location override set');

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
      final prefs = await getUserPreferences(alumnusId);
      if (prefs == null) return false;

      // Check if manual location is set
      if (prefs.manualLocationLatitude == null ||
          prefs.manualLocationLongitude == null) {
        return false;
      }

      // Check if it has an expiration time
      if (prefs.manualLocationExpiresAt == null) {
        // No expiration, keep forever
        return false;
      }

      // Check if expired
      if (DateTime.now().isAfter(prefs.manualLocationExpiresAt!)) {
        print('⏰ SettingsRepository: Manual location expired, clearing...');
        await clearManualLocation(alumnusId);
        return true;
      }

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
