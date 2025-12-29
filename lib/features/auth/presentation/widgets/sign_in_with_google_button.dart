import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleSignIn,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.g_mobiledata, size: 24),
            ),
      label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.textGray),
        ),
      ),
    );
  }
}
