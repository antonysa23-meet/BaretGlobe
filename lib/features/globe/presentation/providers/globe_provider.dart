import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/location.dart';
import '../../data/repositories/location_repository.dart';

part 'globe_provider.g.dart';

/// Provider for location repository
@riverpod
LocationRepository locationRepository(LocationRepositoryRef ref) {
  return LocationRepository();
}

/// Provider for all current alumni locations
@riverpod
class CurrentLocations extends _$CurrentLocations {
  @override
  Future<List<AlumnusLocation>> build() async {
    // Subscribe to real-time changes
    _subscribeToChanges();

    // Fetch initial data
    return _fetchLocations();
  }

  Future<List<AlumnusLocation>> _fetchLocations() async {
    final repository = ref.read(locationRepositoryProvider);
    try {
      print('🔵 GlobeProvider: Fetching locations from database...');
      final locations = await repository.getAllCurrentLocations();
      print('✅ GlobeProvider: Got ${locations.length} locations');
      for (final loc in locations) {
        print('   - ${loc.alumnus.name} at ${loc.location.city ?? "Unknown"}, ${loc.location.country}');
      }
      return locations;
    } catch (e) {
      print('❌ GlobeProvider: Error fetching locations - $e');
      // Return empty list if Supabase is not configured yet
      return [];
    }
  }

  void _subscribeToChanges() {
    final repository = ref.read(locationRepositoryProvider);

    // Listen to real-time location updates from Supabase
    repository.subscribeToLocationChanges().listen((locations) {
      state = AsyncValue.data(locations);
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  /// Refresh locations manually
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocations());
  }
}

/// Provider for checking if a specific alumnus can check in
@riverpod
Future<bool> canCheckIn(CanCheckInRef ref, String alumnusId) async {
  final repository = ref.read(locationRepositoryProvider);
  try {
    return await repository.canCheckIn(alumnusId);
  } catch (e) {
    // If Supabase is not configured, allow check-in
    return true;
  }
}
