import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// User preferences model matching the user_preferences table
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    required String id,
    required String alumnusId,
    required bool locationTrackingEnabled,
    required String locationTrackingFrequency,
    required bool notificationsEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
    // Visibility on globe
    @Default(true) bool visibleOnGlobe,
    // Manual location override fields
    String? manualLocationCity,
    String? manualLocationCountry,
    double? manualLocationLatitude,
    double? manualLocationLongitude,
    DateTime? manualLocationExpiresAt,
  }) = _UserPreferences;

  /// Create from Supabase JSON
  factory UserPreferences.fromSupabaseJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String,
      alumnusId: json['alumnus_id'] as String,
      locationTrackingEnabled: json['location_tracking_enabled'] as bool,
      locationTrackingFrequency: json['location_tracking_frequency'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      visibleOnGlobe: json['visible_on_globe'] as bool? ?? true,
      manualLocationCity: json['manual_location_city'] as String?,
      manualLocationCountry: json['manual_location_country'] as String?,
      manualLocationLatitude: json['manual_location_latitude'] as double?,
      manualLocationLongitude: json['manual_location_longitude'] as double?,
      manualLocationExpiresAt: json['manual_location_expires_at'] != null
          ? DateTime.parse(json['manual_location_expires_at'] as String)
          : null,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

/// Extension for converting to Supabase JSON
extension UserPreferencesX on UserPreferences {
  /// Convert to Supabase JSON format
  static Map<String, dynamic> toSupabaseJson(UserPreferences prefs) {
    return {
      'id': prefs.id,
      'alumnus_id': prefs.alumnusId,
      'location_tracking_enabled': prefs.locationTrackingEnabled,
      'location_tracking_frequency': prefs.locationTrackingFrequency,
      'notifications_enabled': prefs.notificationsEnabled,
      'created_at': prefs.createdAt.toIso8601String(),
      'updated_at': prefs.updatedAt.toIso8601String(),
      'visible_on_globe': prefs.visibleOnGlobe,
      'manual_location_city': prefs.manualLocationCity,
      'manual_location_country': prefs.manualLocationCountry,
      'manual_location_latitude': prefs.manualLocationLatitude,
      'manual_location_longitude': prefs.manualLocationLongitude,
      'manual_location_expires_at': prefs.manualLocationExpiresAt?.toIso8601String(),
    };
  }
}
