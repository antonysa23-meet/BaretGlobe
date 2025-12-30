import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

/// Represents a single message in a conversation
@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    // Extended sender info (from join)
    String? senderName,
    String? senderProfileImageUrl,
    // Read receipts info
    @Default([]) List<String> readByAlumniIds,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  /// Create Message from Supabase JSON (snake_case)
  static Message fromSupabaseJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      senderName: json['sender_name'] as String?,
      senderProfileImageUrl: json['sender_profile_image_url'] as String?,
      readByAlumniIds: json['read_by'] != null
          ? List<String>.from(json['read_by'] as List)
          : [],
    );
  }

  /// Convert Message to Supabase JSON (snake_case) for insert/update
  static Map<String, dynamic> toSupabaseJson(Message message) {
    return {
      'conversation_id': message.conversationId,
      'sender_id': message.senderId,
      'content': message.content,
    };
  }
}
