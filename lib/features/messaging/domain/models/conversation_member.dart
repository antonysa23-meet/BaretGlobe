import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_member.freezed.dart';
part 'conversation_member.g.dart';

/// Represents a member of a conversation
@freezed
class ConversationMember with _$ConversationMember {
  const factory ConversationMember({
    required String id,
    required String conversationId,
    required String alumnusId,
    required DateTime joinedAt,
    DateTime? leftAt,
    required DateTime lastReadAt,
    // Extended alumnus info (from join)
    String? alumnusName,
    int? alumnusCohortYear,
    String? alumnusProfileImageUrl,
  }) = _ConversationMember;

  factory ConversationMember.fromJson(Map<String, dynamic> json) =>
      _$ConversationMemberFromJson(json);

  /// Create ConversationMember from Supabase JSON (snake_case)
  static ConversationMember fromSupabaseJson(Map<String, dynamic> json) {
    return ConversationMember(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      alumnusId: json['alumnus_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null
          ? DateTime.parse(json['left_at'] as String)
          : null,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      alumnusName: json['alumnus_name'] as String?,
      alumnusCohortYear: json['alumnus_cohort_year'] as int?,
      alumnusProfileImageUrl: json['alumnus_profile_image_url'] as String?,
    );
  }
}
