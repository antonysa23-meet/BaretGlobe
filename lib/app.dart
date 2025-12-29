import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_lifecycle_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

/// Root application widget
class BaretScholarsApp extends ConsumerWidget {
  const BaretScholarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to determine which screen to show
    final authState = ref.watch(authStateProvider);

    return AppLifecycleManager(
      child: MaterialApp(
        title: 'Baret Scholars Globe',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        // Home - Show LoginScreen or HomeScreen based on auth state
        home: authState.when(
          data: (state) => state.maybeWhen(
            authenticated: (user, alumnusId) => const HomeScreen(),
            orElse: () => const LoginScreen(),
          ),
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => const LoginScreen(),
        ),
      ),
    );
  }
}
