import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/services/email_validator_service.dart';
import '../../../globe/data/repositories/location_repository.dart';
import '../../../globe/domain/models/alumnus.dart';
import '../../domain/models/auth_user.dart' as app_auth;
import '../services/google_sign_in_service.dart';

/// Repository for handling authentication operations
class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignInService _googleSignInService;
  final LocationRepository _locationRepository;

  AuthRepository({
    required SupabaseClient supabase,
    required GoogleSignInService googleSignInService,
    required LocationRepository locationRepository,
  })  : _supabase = supabase,
        _googleSignInService = googleSignInService,
        _locationRepository = locationRepository;

  /// Get the current authenticated user from Supabase
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Sign in with Google OAuth
  ///
  /// Returns the authenticated user and their alumnus profile
  /// Throws an exception if email domain is invalid or sign-in fails
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Step 1: Get Google credentials
      final googleCredentials = await _googleSignInService.signIn();
      final email = googleCredentials['email'] ?? '';

      // Step 2: Validate email domain
      final validation = EmailValidatorService.validate(email);
      if (!validation.isValid) {
        // Sign out from Google
        await _googleSignInService.signOut();
        throw Exception(validation.errorMessage ?? 'Invalid email domain');
      }

      // Step 3: Sign in to Supabase with Google ID token
      print('🔵 AuthRepository: Signing in to Supabase...');
      print('🔵 AuthRepository: Email = $email');

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleCredentials['idToken']!,
        accessToken: googleCredentials['accessToken'],
      );

      print('🔵 AuthRepository: Supabase response received');
      print('🔵 AuthRepository: User = ${response.user?.id}');
      print('🔵 AuthRepository: Session = ${response.session?.accessToken != null}');

      if (response.user == null) {
        print('❌ AuthRepository: No user in Supabase response');
        throw Exception('Failed to authenticate with Supabase');
      }

      print('✅ AuthRepository: Supabase authentication successful');

      // Step 4: Get or create alumnus profile
      final alumnus = await _getOrCreateAlumnus(
        authUserId: response.user!.id,
        email: email,
        name: googleCredentials['displayName'],
        photoUrl: googleCredentials['photoUrl'],
        provider: 'google',
      );

      return {
        'user': app_auth.AuthUser.fromSupabaseUser(response.user!),
        'alumnus': alumnus,
      };
    } catch (error) {
      throw Exception(
          EmailValidatorService.getOAuthErrorMessage(error.toString()));
    }
  }


  /// Sign out the current user
  Future<void> signOut() async {
    try {
      // Sign out from OAuth providers
      await _googleSignInService.signOut();

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (error) {
      // Ignore sign-out errors
    }
  }

  /// Get current auth user as AuthUser model
  app_auth.AuthUser? getCurrentAuthUser() {
    final user = currentUser;
    if (user == null) return null;
    return app_auth.AuthUser.fromSupabaseUser(user);
  }

  /// Get or create alumnus profile for authenticated user
  ///
  /// Checks if an alumnus profile exists for this auth_user_id
  /// If yes, updates last_login_at and returns it
  /// If no, checks for device_id match (migration), or creates new profile
  Future<Alumnus> _getOrCreateAlumnus({
    required String authUserId,
    required String email,
    String? name,
    String? photoUrl,
    required String provider,
  }) async {
    // Step 1: Check if alumnus already exists by auth_user_id
    final existingAlumnus =
        await _locationRepository.getAlumnusByAuthUserId(authUserId);

    if (existingAlumnus != null) {
      // Update last login time
      final updated = existingAlumnus.copyWith(
        lastLoginAt: DateTime.now(),
        email: email.isNotEmpty ? email : existingAlumnus.email,
        profileImageUrl: photoUrl ?? existingAlumnus.profileImageUrl,
      );
      await _locationRepository.updateAlumnus(updated);
      return updated;
    }

    // Step 2: Check if a device_id user exists (migration scenario)
    // This allows existing users to link their device-based account
    // For now, we'll skip this and just create a new profile
    // TODO: Implement device_id migration logic if needed

    // Step 3: Create new alumnus profile
    // Note: We'll need cohort year and region from user input
    // For now, create with placeholder values
    final newAlumnus = Alumnus(
      id: '', // Will be generated by Supabase
      name: name ?? EmailValidatorService.extractUsername(email) ?? 'Scholar',
      cohortYear: DateTime.now().year, // Placeholder
      cohortRegion: null, // Will be set later
      email: email,
      profileImageUrl: photoUrl,
      authProvider: provider,
      authUserId: authUserId,
      emailVerified: true,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return await _locationRepository.createAlumnusFromAuth(newAlumnus);
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return currentUser != null;
  }

  /// Get alumnus profile for current authenticated user
  Future<Alumnus?> getCurrentAlumnus() async {
    final user = currentUser;
    if (user == null) return null;

    return await _locationRepository.getAlumnusByAuthUserId(user.id);
  }
}
