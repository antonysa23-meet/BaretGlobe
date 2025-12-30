import 'package:freezed_annotation/freezed_annotation.dart';
import 'conversation_member.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

/// Type of conversation
enum ConversationType {
  @JsonValue('direct')
  direct,
  @JsonValue('group')
  group,
  @JsonValue('cohort')
  cohort,
  @JsonValue('country')
  country,
}

/// Represents a conversation (DM, group, cohort group, or country group)
@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required ConversationType type,
    String? name,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? lastMessageSenderId,
    // For auto-managed groups
    int? cohortYear,
    String? countryCode,
    // Extended info (from joins)
    @Default([]) List<ConversationMember> members,
    int? unreadCount,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  /// Create Conversation from Supabase JSON (snake_case)
  static Conversation fromSupabaseJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: _parseConversationType(json['type'] as String),
      name: json['name'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      cohortYear: json['cohort_year'] as int?,
      countryCode: json['country_code'] as String?,
      unreadCount: json['unread_count'] as int?,
    );
  }

  static ConversationType _parseConversationType(String type) {
    switch (type) {
      case 'direct':
        return ConversationType.direct;
      case 'group':
        return ConversationType.group;
      case 'cohort':
        return ConversationType.cohort;
      case 'country':
        return ConversationType.country;
      default:
        return ConversationType.direct;
    }
  }
}
