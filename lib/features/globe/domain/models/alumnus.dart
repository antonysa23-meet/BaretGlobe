import 'package:freezed_annotation/freezed_annotation.dart';

part 'alumnus.freezed.dart';
part 'alumnus.g.dart';

/// Represents a Baret Scholars alumnus
@freezed
class Alumnus with _$Alumnus {
  const factory Alumnus({
    required String id,
    required String name,
    required int cohortYear,
    String? cohortRegion,
    String? email,
    String? profileImageUrl,
    String? bio,
    String? deviceId,
    // Authentication fields
    String? authProvider, // 'google' or 'apple'
    String? authUserId, // Reference to Supabase auth.users
    bool? emailVerified,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Alumnus;

  factory Alumnus.fromJson(Map<String, dynamic> json) => _$AlumnusFromJson(json);

  /// Convert to Supabase JSON format (snake_case)
  static Map<String, dynamic> toSupabaseJson(Alumnus alumnus) {
    final json = <String, dynamic>{
      'name': alumnus.name,
      'cohort_year': alumnus.cohortYear,
      'cohort_region': alumnus.cohortRegion,
      'email': alumnus.email,
      'profile_image_url': alumnus.profileImageUrl,
      'bio': alumnus.bio,
      'device_id': alumnus.deviceId,
      'auth_provider': alumnus.authProvider,
      'auth_user_id': alumnus.authUserId,
      'email_verified': alumnus.emailVerified,
      'last_login_at': alumnus.lastLoginAt?.toIso8601String(),
      'created_at': alumnus.createdAt?.toIso8601String(),
      'updated_at': alumnus.updatedAt?.toIso8601String(),
    };

    // Only include ID if it's not empty (for updates, not inserts)
    if (alumnus.id.isNotEmpty) {
      json['id'] = alumnus.id;
    }

    return json;
  }

  /// Create from Supabase JSON format (snake_case)
  static Alumnus fromSupabaseJson(Map<String, dynamic> json) {
    return Alumnus(
      id: json['id'] as String,
      name: json['name'] as String,
      cohortYear: json['cohort_year'] as int,
      cohortRegion: json['cohort_region'] as String?,
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      deviceId: json['device_id'] as String?,
      authProvider: json['auth_provider'] as String?,
      authUserId: json['auth_user_id'] as String?,
      emailVerified: json['email_verified'] as bool?,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
