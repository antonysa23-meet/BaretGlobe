import 'package:google_sign_in/google_sign_in.dart';

/// Service wrapper for Google Sign-In
class GoogleSignInService {
  late final GoogleSignIn _googleSignIn;

  GoogleSignInService({
    String? clientId,
    List<String> scopes = const ['email', 'profile'],
  }) {
    _googleSignIn = GoogleSignIn(
      clientId: clientId,
      scopes: scopes,
    );
  }

  /// Sign in with Google and return the ID token
  ///
  /// Returns a Map with 'idToken' and 'accessToken'
  /// Throws an exception if sign-in fails
  Future<Map<String, String>> signIn() async {
    try {
      print('🔵 GoogleSignInService: Starting sign-in flow...');

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🔵 GoogleSignInService: Got user response: ${googleUser?.email ?? "null"}');

      if (googleUser == null) {
        // User cancelled the sign-in
        print('❌ GoogleSignInService: User cancelled');
        throw Exception('Sign-in cancelled by user');
      }

      print('🔵 GoogleSignInService: Getting authentication tokens...');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔵 GoogleSignInService: ID Token present: ${googleAuth.idToken != null}');
      print('🔵 GoogleSignInService: Access Token present: ${googleAuth.accessToken != null}');

      // Ensure we have both tokens
      if (googleAuth.idToken == null) {
        print('❌ GoogleSignInService: ID token is null');
        throw Exception('Failed to obtain Google ID token');
      }

      if (googleAuth.accessToken == null) {
        print('❌ GoogleSignInService: Access token is null');
        throw Exception('Failed to obtain Google access token');
      }

      print('✅ GoogleSignInService: Sign-in successful for ${googleUser.email}');

      return {
        'idToken': googleAuth.idToken!,
        'accessToken': googleAuth.accessToken!,
        'email': googleUser.email,
        'displayName': googleUser.displayName ?? '',
        'photoUrl': googleUser.photoUrl ?? '',
      };
    } catch (error) {
      // Re-throw with more context
      print('❌ GoogleSignInService: Error - $error');
      throw Exception('Google Sign-In failed: $error');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      // Ignore sign-out errors (user might not be signed in)
    }
  }

  /// Disconnect the Google account (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      // Ignore disconnect errors
    }
  }

  /// Check if a user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get the currently signed-in Google user (if any)
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }
}
