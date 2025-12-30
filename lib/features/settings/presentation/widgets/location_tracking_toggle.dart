import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Toggle widget for location tracking with permission handling
class LocationTrackingToggle extends ConsumerStatefulWidget {
  final bool enabled;
  final Function(bool) onChanged;

  const LocationTrackingToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  ConsumerState<LocationTrackingToggle> createState() =>
      _LocationTrackingToggleState();
}

class _LocationTrackingToggleState
    extends ConsumerState<LocationTrackingToggle> {
  bool _isLoading = false;
  final LocationService _locationService = LocationService();

  Future<void> _handleToggle(bool value) async {
    if (_isLoading) return;

    if (value) {
      // Enabling - need to check permissions
      setState(() => _isLoading = true);

      try {
        // Check if location service is enabled
        final serviceEnabled =
            await _locationService.isLocationServiceEnabled();
        if (!serviceEnabled && mounted) {
          _showLocationServiceDialog();
          setState(() => _isLoading = false);
          return;
        }

        // Check permission
        LocationPermission permission =
            await _locationService.checkPermission();

        // Request if denied
        if (permission == LocationPermission.denied) {
          permission = await _locationService.requestPermission();
        }

        if (permission == LocationPermission.denied && mounted) {
          _showPermissionDeniedDialog();
          setState(() => _isLoading = false);
          return;
        }

        if (permission == LocationPermission.deniedForever && mounted) {
          _showPermissionPermanentlyDeniedDialog();
          setState(() => _isLoading = false);
          return;
        }

        // On Android, also request background location permission
        if (Platform.isAndroid) {
          final backgroundStatus = await ph.Permission.locationAlways.status;

          if (!backgroundStatus.isGranted) {
            // Show explanation dialog
            final shouldRequest = await _showBackgroundPermissionExplanation();

            if (shouldRequest && mounted) {
              final backgroundPermission =
                  await ph.Permission.locationAlways.request();

              if (!backgroundPermission.isGranted && mounted) {
                // User can still use foreground tracking
                _showBackgroundPermissionDeniedInfo();
              }
            }
          }
        }

        // Permission granted, toggle on
        await widget.onChanged(true);
      } catch (error) {
        print('❌ LocationTrackingToggle: Error - $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error enabling location tracking: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Disabling - just turn off
      setState(() => _isLoading = true);
      try {
        await widget.onChanged(false);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use location tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarySage,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is required to share your location with the Baret Scholars community. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleToggle(true); // Try again
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarySage,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it in app settings to use location tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarySage,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showBackgroundPermissionExplanation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Location Access'),
        content: const Text(
          'To keep your location updated even when the app is closed, we need permission to access your location in the background.\n\n'
          'On the next screen, please select "Allow all the time" to enable continuous tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarySage,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showBackgroundPermissionDeniedInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limited Location Access'),
        content: const Text(
          'Without background location permission, your location will only update when the app is open.\n\n'
          'You can still use location tracking, but it won\'t work when the app is closed.\n\n'
          'To enable background tracking later, go to Settings > Apps > Baret Globe > Permissions > Location > Allow all the time.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondarySage,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Enable Location Tracking',
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        widget.enabled
            ? 'Your location is being shared'
            : 'Turn on to appear on the map',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textGray),
      ),
      value: widget.enabled,
      activeThumbColor: AppColors.accentGold,
      onChanged: _isLoading ? null : _handleToggle,
      secondary: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              widget.enabled ? Icons.location_on : Icons.location_off,
              color: widget.enabled ? AppColors.accentGold : AppColors.textGray,
            ),
    );
  }
}
