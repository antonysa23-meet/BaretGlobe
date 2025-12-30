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
              Image.asset(
                'assets/images/Baret.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 1,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'GLOBAL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 1,
                    color: AppColors.accentGold,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tagline
              const Text(
                'Connect with the Baret alumni worldwide',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 64),

              // Email requirement notice
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.neutralGray100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentGold,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Make sure to sign in with your Baret email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
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
