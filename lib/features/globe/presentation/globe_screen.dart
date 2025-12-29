import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/models/location.dart';
import 'providers/globe_provider.dart';

/// Main globe screen showing alumni locations on a map
class GlobeScreen extends ConsumerStatefulWidget {
  const GlobeScreen({super.key});

  @override
  ConsumerState<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends ConsumerState<GlobeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 1.2;

  // Zoom momentum tracking
  late AnimationController _zoomAnimationController;
  Animation<double>? _zoomAnimation;
  double _lastZoomVelocity = 0.0;
  DateTime _lastZoomTime = DateTime.now();
  double _previousZoom = 1.2;
  LatLng? _previousCenter;

  @override
  void initState() {
    super.initState();
    // Initialize zoom momentum animation controller
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addListener(() {
        if (_zoomAnimation != null) {
          final newZoom = _zoomAnimation!.value;
          final center = _mapController.camera.center;
          _mapController.move(center, newZoom);
        }
      })
      ..addStatusListener((status) {
        // When zoom animation completes, stop any horizontal momentum
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          // Force stop any ongoing map movement by moving to current position
          final currentCenter = _mapController.camera.center;
          final currentZoom = _mapController.camera.zoom;
          _mapController.move(currentCenter, currentZoom);
        }
      });
  }

  @override
  void dispose() {
    _zoomAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the locations from database
    final locationsAsync = ref.watch(currentLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baret Scholars Globe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => _centerOnAllLocations(locationsAsync.value ?? []),
            tooltip: 'View all locations',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(currentLocationsProvider),
            tooltip: 'Refresh locations',
          ),
        ],
      ),
      body: locationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading locations: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentLocationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (locations) => _buildMap(context, locations),
      ),
      bottomNavigationBar: locationsAsync.maybeWhen(
        data: (locations) => _buildBottomBar(context, locations),
        orElse: () => null,
      ),
    );
  }

  Widget _buildMap(BuildContext context, List<AlumnusLocation> locations) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(0.0, 0.0), // Center of world
        initialZoom: 1.2, // Zoomed out to see full globe
        minZoom: 1.5, // Allow zooming out more
        maxZoom: 10.0, // Increased max zoom for better detail
        // No camera constraint - enables infinite horizontal scrolling
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          enableMultiFingerGestureRace: true,
          // Improved pinch-zoom settings
          pinchMoveThreshold: 20.0, // Lower = more responsive zoom centering
          pinchZoomThreshold: 0.3, // More sensitive zoom detection
          scrollWheelVelocity: 0.005,
        ),
        backgroundColor: Colors.transparent,
        onPositionChanged: (position, hasGesture) {
          final newZoom = position.zoom ?? 1.2;
          final newCenter = position.center;
          final now = DateTime.now();
          final timeDiff = now.difference(_lastZoomTime).inMilliseconds;

          // Check if user is panning (map center is moving)
          bool isPanning = false;
          if (_previousCenter != null && newCenter != null) {
            final distance = _calculateDistance(_previousCenter!, newCenter);
            // If center moved more than 0.01 degrees, user is panning
            isPanning = distance > 0.01;
          }

          // Calculate zoom velocity only if not panning significantly
          if (timeDiff > 0 && hasGesture && !isPanning) {
            _lastZoomVelocity = (newZoom - _previousZoom) / timeDiff * 1000;
            _lastZoomTime = now;
            _previousZoom = newZoom;
          } else if (isPanning) {
            // Reset velocity if panning detected
            _lastZoomVelocity = 0.0;
          }

          // Update previous center
          _previousCenter = newCenter;

          // When gesture ends, apply momentum only if there's significant velocity
          if (!hasGesture && _lastZoomVelocity.abs() > 0.01) {
            _applyZoomMomentum(newZoom, _lastZoomVelocity);
            _lastZoomVelocity = 0.0;
          }

          setState(() {
            _currentZoom = newZoom;
          });
        },
      ),
      children: [
        // Single tile layer for 100% clarity
        TileLayer(
          // urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
          // 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          // 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png',
          // 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
          // 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',

          userAgentPackageName: 'com.baret.scholars_globe',
          tileDisplay: const TileDisplay.instantaneous(),
        ),

        // Location markers with clustering
        MarkerLayer(
          markers: _buildClusteredMarkers(context, locations),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
      BuildContext context, List<AlumnusLocation> locations) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${locations.length} Alumni Worldwide',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap markers to see details',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to check-in screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check-in screen coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.add_location),
              label: const Text('Check In'),
            ),
          ],
        ),
      ),
    );
  }

  // Build clustered markers based on proximity and zoom level
  List<Marker> _buildClusteredMarkers(
      BuildContext context, List<AlumnusLocation> locations) {
    // Convert AlumnusLocation to MarkerData
    final markerDataList = locations.map((alumnusLoc) {
      return MarkerData(
        name: alumnusLoc.alumnus.name,
        cohortYear: alumnusLoc.alumnus.cohortYear,
        location:
            LatLng(alumnusLoc.location.latitude, alumnusLoc.location.longitude),
        city: alumnusLoc.location.city ?? 'Unknown',
        country: alumnusLoc.location.country,
        updatedAt: alumnusLoc.location.createdAt,
      );
    }).toList();

    final clusters = <String, List<MarkerData>>{};
    final clusterRadius = _getClusterRadius();

    // Group nearby locations
    for (final data in markerDataList) {
      bool addedToCluster = false;

      // Only cluster if radius > 0 (not at max zoom)
      if (clusterRadius > 0) {
        for (final key in clusters.keys) {
          final clusterLocation = clusters[key]!.first.location;
          final distance = _calculateDistance(data.location, clusterLocation);

          if (distance < clusterRadius) {
            clusters[key]!.add(data);
            addedToCluster = true;
            break;
          }
        }
      }

      if (!addedToCluster) {
        final key =
            '${data.location.latitude.toStringAsFixed(6)}_${data.location.longitude.toStringAsFixed(6)}';
        clusters[key] = [data];
      }
    }

    // Build markers from clusters
    return clusters.entries.map((entry) {
      final alumniList = entry.value;
      final location = alumniList.first.location;

      if (alumniList.length == 1) {
        // Single marker
        return Marker(
          point: location,
          width: 32,
          height: 32,
          child: GestureDetector(
            onTap: () => _showLocationDetails(context, alumniList.first),
            child: _buildSingleMarker(alumniList.first),
          ),
        );
      } else if (_currentZoom >= 9.8) {
        // At very high zoom, show individual profiles with badge
        return Marker(
          point: location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showClusterDetails(context, alumniList),
            child: _buildProfileWithBadge(alumniList),
          ),
        );
      } else {
        // Cluster marker for lower zoom levels
        return Marker(
          point: location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showClusterDetails(context, alumniList),
            child: _buildClusterMarker(alumniList),
          ),
        );
      }
    }).toList();
  }

  double _getClusterRadius() {
    // Adjust cluster radius based on zoom level
    // More zoom = smaller radius = less clustering
    // Refined thresholds for better separation as user zooms in
    if (_currentZoom < 2)
      return 500.0; // World view - very aggressive clustering
    if (_currentZoom < 3) return 100.0; // Continental view
    if (_currentZoom < 4) return 20.0; // Multi-country view
    if (_currentZoom < 5)
      return 5.0; // Country level - countries should separate here
    if (_currentZoom < 6) return 1.0; // Country zoom - cities start separating
    if (_currentZoom < 7.5)
      return 0.5; // Regional view - nearby cities separate
    if (_currentZoom < 9) return 0.1; // City view - neighborhoods separate
    if (_currentZoom < 9.8)
      return 0.01; // Close zoom - very close locations separate
    return 0.0; // Max zoom - fully separate (same exact location)
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple Euclidean distance (good enough for clustering)
    final latDiff = point1.latitude - point2.latitude;
    final lngDiff = point1.longitude - point2.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff);
  }

  Widget _buildSingleMarker(MarkerData data) {
    final color = AppColors.getCohortColor(data.cohortYear);

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildProfileWithBadge(List<MarkerData> alumni) {
    // Show first person's profile with a badge indicating count
    final firstPerson = alumni.first;
    final color = AppColors.getCohortColor(firstPerson.cohortYear);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main profile marker
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        // Badge in top right
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Center(
              child: Text(
                '${alumni.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClusterMarker(List<MarkerData> alumni) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${alumni.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showClusterDetails(BuildContext context, List<MarkerData> alumni) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${alumni.length} Alumni at this location',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: alumni.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final data = alumni[index];
                  final lastUpdated = data.updatedAt != null
                      ? ' • ${_formatRelativeTime(data.updatedAt!)}'
                      : '';
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.getCohortColor(data.cohortYear),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(data.name),
                    subtitle: Text(
                        'Cohort ${data.cohortYear} • ${data.city}$lastUpdated'),
                    onTap: () {
                      Navigator.pop(context);
                      _showLocationDetails(context, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(BuildContext context, MarkerData data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.getCohortColor(data.cohortYear),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cohort ${data.cohortYear}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.location_city, data.city),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.public, data.country),
            const SizedBox(height: 8),
            if (data.updatedAt != null)
              _buildDetailRow(
                Icons.schedule,
                'Last updated ${_formatRelativeTime(data.updatedAt!)}',
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(data.location, 10.0);
                },
                child: const Text('Zoom to Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondarySage),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// Format a DateTime as relative time (today, yesterday, a week ago, etc)
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Today (within last 24 hours)
    if (difference.inHours < 24 && now.day == dateTime.day) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }

    // Yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'yesterday';
    }

    // Within a week
    if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }

    // Within a month (approximately 30 days)
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }

    // Within a year (approximately 365 days)
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    // More than a year
    return 'a long time ago';
  }

  void _centerOnAllLocations(List<AlumnusLocation> locations) {
    if (locations.isEmpty) return;

    // Calculate bounds that include all markers
    double minLat = locations.first.location.latitude;
    double maxLat = locations.first.location.latitude;
    double minLng = locations.first.location.longitude;
    double maxLng = locations.first.location.longitude;

    for (final alumnusLoc in locations) {
      final lat = alumnusLoc.location.latitude;
      final lng = alumnusLoc.location.longitude;
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    _mapController.move(center, 2.5);
  }

  void _applyZoomMomentum(double currentZoom, double velocity) {
    // Calculate target zoom based on velocity with decay
    final momentumAmount =
        velocity * 0.3; // Adjust multiplier for stronger/weaker effect
    final targetZoom = (currentZoom + momentumAmount).clamp(0.8, 10.0);

    // Only apply momentum if there's a meaningful change
    if ((targetZoom - currentZoom).abs() < 0.01) return;

    // Create smooth deceleration animation
    _zoomAnimation = Tween<double>(
      begin: currentZoom,
      end: targetZoom,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController,
      curve: Curves.decelerate,
    ));

    _zoomAnimationController.reset();
    _zoomAnimationController.forward();
  }
}

/// Data class for marker information
class MarkerData {
  final String name;
  final int cohortYear;
  final LatLng location;
  final String city;
  final String country;
  final DateTime? updatedAt;

  MarkerData({
    required this.name,
    required this.cohortYear,
    required this.location,
    required this.city,
    required this.country,
    this.updatedAt,
  });
}
