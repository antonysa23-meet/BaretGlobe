import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../globe/data/repositories/location_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/google_sign_in_service.dart';
import '../../domain/models/auth_state.dart' as app_auth;
import '../../domain/models/auth_user.dart' as app_auth;

// ==================
// SERVICE PROVIDERS
// ==================

/// Google Sign-In service provider
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService(
    // Use the Web Client ID from Google Cloud Console (for Supabase OAuth)
    clientId: '709491317231-3l2b2ptjkh5o5o1uq2pq2gte9bnkdhmg.apps.googleusercontent.com',
  );
});

/// Location repository provider
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

// ==================
// AUTH REPOSITORY
// ==================

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabase: Supabase.instance.client,
    googleSignInService: ref.read(googleSignInServiceProvider),
    locationRepository: ref.read(locationRepositoryProvider),
  );
});

// ==================
// AUTH STATE
// ==================

/// Current auth state provider
///
/// Listens to Supabase auth changes and provides the current auth state
final authStateProvider = StreamProvider<app_auth.AuthState>((ref) {
  final authRepo = ref.read(authRepositoryProvider);

  return authRepo.authStateChanges.asyncMap((authState) async {
    final user = authState.session?.user;

    if (user == null) {
      return const app_auth.AuthState.unauthenticated();
    }

    try {
      // Get the alumnus profile for this user
      final alumnus = await authRepo.getCurrentAlumnus();

      if (alumnus == null) {
        // User is authenticated but no alumnus profile
        // This shouldn't happen, but handle it gracefully
        return const app_auth.AuthState.unauthenticated();
      }

      return app_auth.AuthState.authenticated(
        user: app_auth.AuthUser.fromSupabaseUser(user),
        alumnusId: alumnus.id,
      );
    } catch (error) {
      return app_auth.AuthState.error(
        message: error.toString(),
      );
    }
  });
});

/// Current authenticated user provider
final currentUserProvider = Provider<app_auth.AuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.whenData((state) {
    return state.maybeWhen(
      authenticated: (user, alumnusId) => user,
      orElse: () => null,
    );
  }).value;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.whenData((state) {
    return state.maybeWhen(
      authenticated: (user, alumnusId) => true,
      orElse: () => false,
    );
  }).value ?? false;
});
