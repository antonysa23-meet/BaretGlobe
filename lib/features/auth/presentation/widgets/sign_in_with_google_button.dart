import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../globe/data/repositories/location_repository.dart';
import '../providers/auth_provider.dart';
import 'cohort_selection_dialog.dart';

/// Google Sign-In button widget
class SignInWithGoogleButton extends ConsumerStatefulWidget {
  const SignInWithGoogleButton({super.key});

  @override
  ConsumerState<SignInWithGoogleButton> createState() =>
      _SignInWithGoogleButtonState();
}

class _SignInWithGoogleButtonState
    extends ConsumerState<SignInWithGoogleButton> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    try {
      print('🔵 Starting Google Sign-In...');
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      print('✅ Sign-In successful!');

      // Check if this is a new user (cohort year is current year = placeholder)
      final alumnus = result['alumnus'];
      final isNewUser = alumnus.cohortYear == DateTime.now().year &&
                        alumnus.cohortRegion == null;

      if (isNewUser && mounted) {
        // Show cohort selection dialog
        final cohortData = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CohortSelectionDialog(),
        );

        if (cohortData != null) {
          // Update alumnus with cohort information
          final locationRepo = LocationRepository();
          final updatedAlumnus = alumnus.copyWith(
            cohortYear: cohortData['year'] as int,
            cohortRegion: cohortData['region'] as String,
          );
          await locationRepo.updateAlumnus(updatedAlumnus);
          print('✅ Cohort information updated');

          // Refresh auth state to trigger navigation to HomeScreen
          ref.invalidate(authStateProvider);

          // IMPORTANT: Immediately get user's location after cohort setup
          print('📍 Triggering immediate location update for new user...');
          await _getInitialLocation(updatedAlumnus.id);
        }
      }

      // The authStateProvider will automatically navigate to HomeScreen
      // once it detects the authenticated state
      print('✅ Authentication complete - navigating to home...');
    } catch (error, stackTrace) {
      print('❌ Sign-In Error: $error');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Get initial location for new user immediately after signup
  Future<void> _getInitialLocation(String alumnusId) async {
    try {
      print('📍 Getting initial location for new user...');

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      print('📍 Got position: ${position.latitude}, ${position.longitude}');

      // Geocode to city and country
      final geocodingService = GeocodingService();
      final city = await geocodingService.approximateToNearestCity(
        position.latitude,
        position.longitude,
      );
      final country = await geocodingService.getCountry(
        position.latitude,
        position.longitude,
      );

      print('📍 City: $city, Country: $country');

      // Update location in database
      final locationRepo = LocationRepository();
      await locationRepo.updateLocationWithFunction(
        alumnusId: alumnusId,
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country ?? 'Unknown',
        locationType: 'gps',
        notes: 'Initial location after signup',
      );

      print('✅ Initial location saved successfully');
    } catch (error) {
      print('❌ Error getting initial location: $error');
      // Don't throw - location tracking will continue in background
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: const Color(0xFF1F1F1F), // Google's text color
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Pill-shaped like Google
            side: const BorderSide(
              color: Color(0xFF747775), // Google's border color
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
                ),
              )
            else
              const _GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              _isLoading ? 'Signing in...' : 'Sign in with Google',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google logo widget that displays the official multicolor G
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Show a simple blue 'G' if image fails to load
        return const Icon(
          Icons.g_mobiledata,
          size: 24,
          color: Color(0xFF4285F4),
        );
      },
    );
  }
}
