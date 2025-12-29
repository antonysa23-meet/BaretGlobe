import 'package:freezed_annotation/freezed_annotation.dart';
import 'alumnus.dart';

part 'location.freezed.dart';
part 'location.g.dart';

/// Location type enum
enum LocationType {
  @JsonValue('background')
  background,
  @JsonValue('manual')
  manual,
  @JsonValue('check_in')
  checkIn,
}

/// Represents a location record
@freezed
class Location with _$Location {
  const factory Location({
    required String id,
    required String alumnusId,
    required double latitude,
    required double longitude,
    String? city,
    required String country,
    @Default(LocationType.manual) LocationType locationType,
    String? notes,
    @Default(true) bool isCurrent,
    DateTime? createdAt,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  /// Convert to Supabase JSON format (snake_case)
  static Map<String, dynamic> toSupabaseJson(Location location) {
    return {
      'id': location.id,
      'alumnus_id': location.alumnusId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'city': location.city,
      'country': location.country,
      'location_type': location.locationType.name,
      'notes': location.notes,
      'is_current': location.isCurrent,
      'created_at': location.createdAt?.toIso8601String(),
    };
  }

  /// Create from Supabase JSON format (snake_case)
  static Location fromSupabaseJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      alumnusId: json['alumnus_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String,
      locationType: _parseLocationType(json['location_type'] as String?),
      notes: json['notes'] as String?,
      isCurrent: json['is_current'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static LocationType _parseLocationType(String? type) {
    switch (type) {
      case 'background':
        return LocationType.background;
      case 'check_in':
        return LocationType.checkIn;
      default:
        return LocationType.manual;
    }
  }
}

/// Represents an alumnus with their current location
@freezed
class AlumnusLocation with _$AlumnusLocation {
  const factory AlumnusLocation({
    required Alumnus alumnus,
    required Location location,
  }) = _AlumnusLocation;

  factory AlumnusLocation.fromJson(Map<String, dynamic> json) =>
      _$AlumnusLocationFromJson(json);

  /// Create from Supabase joined query result
  static AlumnusLocation fromSupabaseJson(Map<String, dynamic> json) {
    return AlumnusLocation(
      alumnus: Alumnus.fromSupabaseJson({
        'id': json['alumnus_id'],
        'name': json['alumnus_name'],
        'cohort_year': json['cohort_year'],
        'cohort_region': json['cohort_region'],
      }),
      location: Location.fromSupabaseJson({
        'id': json['id'] ?? '',
        'alumnus_id': json['alumnus_id'],
        'latitude': json['latitude'],
        'longitude': json['longitude'],
        'city': json['city'],
        'country': json['country'],
        'location_type': 'manual',
        'notes': json['location_notes'],
        'is_current': true,
        'created_at': json['updated_at'],
      }),
    );
  }
}

/// 3D coordinates for globe visualization
@freezed
class GlobeCoordinates with _$GlobeCoordinates {
  const factory GlobeCoordinates({
    required double x,
    required double y,
    required double z,
  }) = _GlobeCoordinates;

  factory GlobeCoordinates.fromJson(Map<String, dynamic> json) =>
      _$GlobeCoordinatesFromJson(json);

  /// Convert latitude/longitude to 3D coordinates on a sphere
  /// Formula: https://en.wikipedia.org/wiki/Spherical_coordinate_system
  factory GlobeCoordinates.fromLatLng({
    required double latitude,
    required double longitude,
    double radius = 1.0,
  }) {
    const pi = 3.14159265359;

    // Convert to radians
    final phi = (90 - latitude) * (pi / 180);
    final theta = (longitude + 180) * (pi / 180);

    // Spherical to Cartesian conversion
    final x = -(radius * _sin(phi) * _cos(theta));
    final y = radius * _cos(phi);
    final z = radius * _sin(phi) * _sin(theta);

    return GlobeCoordinates(x: x, y: y, z: z);
  }

  static double _sin(double angle) {
    return angle.isNaN ? 0.0 : angle; // Simplified for example
  }

  static double _cos(double angle) {
    return angle.isNaN ? 0.0 : angle; // Simplified for example
  }
}
