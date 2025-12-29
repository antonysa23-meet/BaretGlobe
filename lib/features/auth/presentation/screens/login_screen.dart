import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/sign_in_with_google_button.dart';

/// Login screen with Google Sign-In
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Branding
              const Icon(
                Icons.public,
                size: 100,
                color: AppColors.secondarySage,
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                'Baret Scholars Globe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              const Text(
                'Connect with alumni worldwide',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 48),

              // Email requirement notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.softGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondarySage.withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.secondarySage,
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in with your @baretscholars.org email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign-in button
              const SignInWithGoogleButton(),

              const SizedBox(height: 32),

              // Privacy note
              Text(
                'By signing in, you agree to share your location with fellow Baret Scholars alumni.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
