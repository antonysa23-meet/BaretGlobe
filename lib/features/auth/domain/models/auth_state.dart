import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_user.dart';

part 'auth_state.freezed.dart';

/// Represents the authentication state of the app
@freezed
class AuthState with _$AuthState {
  /// User is not authenticated
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// User is authenticated
  const factory AuthState.authenticated({
    required AuthUser user,
    String? alumnusId, // Link to alumnus profile
  }) = _Authenticated;

  /// Authentication is in progress
  const factory AuthState.loading() = _Loading;

  /// Authentication error occurred
  const factory AuthState.error({
    required String message,
    String? code,
  }) = _Error;
}
