import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// Represents an authenticated user from Supabase Auth
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id, // Supabase auth user ID
    required String email,
    String? name,
    String? photoUrl,
    required String provider, // 'google' or 'apple'
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);

  /// Create AuthUser from Supabase User object
  factory AuthUser.fromSupabaseUser(dynamic user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['full_name'] as String?,
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      provider: user.appMetadata?['provider'] as String? ?? 'email',
      emailVerifiedAt: user.emailConfirmedAt != null
          ? DateTime.parse(user.emailConfirmedAt!)
          : null,
      createdAt:
          user.createdAt != null ? DateTime.parse(user.createdAt!) : null,
    );
  }
}
