import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/alumnus.dart';
import '../../domain/models/location.dart';
import '../../../../core/constants/api_constants.dart';

/// Repository for managing location data
class LocationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================
  // ALUMNI METHODS
  // ==================

  /// Create a new alumnus profile
  Future<Alumnus> createAlumnus({
    required String name,
    required int cohortYear,
    String? cohortRegion,
    String? email,
    String? deviceId,
  }) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .insert({
          'name': name,
          'cohort_year': cohortYear,
          'cohort_region': cohortRegion,
          'email': email,
          'device_id': deviceId,
        })
        .select()
        .single();

    return Alumnus.fromSupabaseJson(response);
  }

  /// Get alumnus by ID
  Future<Alumnus?> getAlumnus(String id) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Alumnus.fromSupabaseJson(response);
  }

  /// Get alumnus by device ID
  Future<Alumnus?> getAlumnusByDevice(String deviceId) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .select()
        .eq('device_id', deviceId)
        .maybeSingle();

    if (response == null) return null;
    return Alumnus.fromSupabaseJson(response);
  }

  /// Get all alumni
  Future<List<Alumnus>> getAllAlumni() async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .select()
        .order('name');

    return (response as List)
        .map((json) => Alumnus.fromSupabaseJson(json))
        .toList();
  }

  /// Update alumnus profile
  Future<Alumnus> updateAlumnus(Alumnus alumnus) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .update(Alumnus.toSupabaseJson(alumnus))
        .eq('id', alumnus.id)
        .select()
        .single();

    return Alumnus.fromSupabaseJson(response);
  }

  /// Get alumnus by auth user ID
  Future<Alumnus?> getAlumnusByAuthUserId(String authUserId) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (response == null) return null;
    return Alumnus.fromSupabaseJson(response);
  }

  /// Create alumnus profile from authenticated user
  Future<Alumnus> createAlumnusFromAuth(Alumnus alumnus) async {
    final response = await _supabase
        .from(ApiConstants.alumniTable)
        .insert(Alumnus.toSupabaseJson(alumnus))
        .select()
        .single();

    return Alumnus.fromSupabaseJson(response);
  }

  // ==================
  // LOCATION METHODS
  // ==================

  /// Add a new location
  Future<Location> addLocation({
    required String alumnusId,
    required double latitude,
    required double longitude,
    String? city,
    required String country,
    LocationType locationType = LocationType.manual,
    String? notes,
  }) async {
    final response = await _supabase
        .from(ApiConstants.locationsTable)
        .insert({
          'alumnus_id': alumnusId,
          'latitude': latitude,
          'longitude': longitude,
          'city': city,
          'country': country,
          'location_type': locationType.name,
          'notes': notes,
          'is_current': true,
        })
        .select()
        .single();

    return Location.fromSupabaseJson(response);
  }

  /// Update location using database function
  Future<String> updateLocationWithFunction({
    required String alumnusId,
    required double latitude,
    required double longitude,
    String? city,
    required String country,
    String locationType = 'manual',
    String? notes,
  }) async {
    final response = await _supabase.rpc(
      ApiConstants.updateLocationFunction,
      params: {
        'p_alumnus_id': alumnusId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_city': city,
        'p_country': country,
        'p_location_type': locationType,
        'p_notes': notes,
      },
    );

    return response as String; // Returns new location ID
  }

  /// Update current location (for background/foreground updates)
  Future<String> updateCurrentLocation({
    required String alumnusId,
    required double latitude,
    required double longitude,
    String? city,
    required String country,
  }) async {
    return await updateLocationWithFunction(
      alumnusId: alumnusId,
      latitude: latitude,
      longitude: longitude,
      city: city,
      country: country,
      locationType: 'background',
      notes: 'Automatic location update',
    );
  }

  /// Get current location for an alumnus
  Future<Location?> getCurrentLocation(String alumnusId) async {
    final response = await _supabase
        .from(ApiConstants.locationsTable)
        .select()
        .eq('alumnus_id', alumnusId)
        .eq('is_current', true)
        .maybeSingle();

    if (response == null) return null;
    return Location.fromSupabaseJson(response);
  }

  /// Get all current locations (for globe visualization)
  Future<List<AlumnusLocation>> getAllCurrentLocations() async {
    final response = await _supabase
        .rpc(ApiConstants.getCurrentLocationsFunction);

    return (response as List)
        .map((json) => AlumnusLocation.fromSupabaseJson(json))
        .toList();
  }

  /// Check if alumnus can check in (rate limiting)
  Future<bool> canCheckIn(String alumnusId) async {
    final response = await _supabase
        .rpc(ApiConstants.canCheckInFunction, params: {
      'p_alumnus_id': alumnusId,
    });

    return response as bool;
  }

  /// Get location history for an alumnus
  Future<List<Location>> getLocationHistory(String alumnusId) async {
    final response = await _supabase
        .from(ApiConstants.locationHistoryTable)
        .select()
        .eq('alumnus_id', alumnusId)
        .order('timestamp', ascending: false);

    return (response as List)
        .map((json) => Location.fromSupabaseJson(json))
        .toList();
  }

  // ==================
  // REALTIME METHODS
  // ==================

  /// Subscribe to location changes
  Stream<List<AlumnusLocation>> subscribeToLocationChanges() {
    return _supabase
        .from(ApiConstants.locationsTable)
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getAllCurrentLocations());
  }

  /// Subscribe to specific alumnus location changes
  Stream<Location?> subscribeToAlumnusLocation(String alumnusId) {
    return _supabase
        .from(ApiConstants.locationsTable)
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter the stream data for the specific alumnus and current location
          final filtered = data.where((item) =>
            item['alumnus_id'] == alumnusId &&
            item['is_current'] == true
          );
          if (filtered.isEmpty) return null;
          return Location.fromSupabaseJson(filtered.first);
        });
  }

  /// Subscribe to new alumni
  Stream<List<Alumnus>> subscribeToAlumni() {
    return _supabase
        .from(ApiConstants.alumniTable)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data.map((json) => Alumnus.fromSupabaseJson(json)).toList());
  }

  // ==================
  // DATA RETENTION
  // ==================

  /// Cleanup old location history (older than 12 months)
  Future<int> cleanupOldLocationHistory() async {
    try {
      final result = await _supabase.rpc('cleanup_old_location_history');
      return result[0]['deleted_count'] as int? ?? 0;
    } catch (error) {
      // If stored function doesn't exist, use app-level cleanup
      final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365));
      await _supabase
          .from(ApiConstants.locationHistoryTable)
          .delete()
          .lt('created_at', twelveMonthsAgo.toIso8601String());
      return 0;
    }
  }

  /// Get the last location update time for an alumnus
  Future<DateTime?> getLastLocationUpdateTime(String alumnusId) async {
    final response = await _supabase
        .from(ApiConstants.locationsTable)
        .select('created_at')
        .eq('alumnus_id', alumnusId)
        .eq('is_current', true)
        .maybeSingle();

    if (response == null) return null;
    return DateTime.parse(response['created_at'] as String);
  }

  /// Update only the country field for current location
  ///
  /// Used when GPS geocoding fails or returns N/A.
  /// The database trigger will automatically handle country group membership changes.
  Future<void> updateManualCountry({
    required String alumnusId,
    required String country,
  }) async {
    await _supabase.rpc('update_manual_country', params: {
      'p_alumnus_id': alumnusId,
      'p_country': country,
    });
  }
}
