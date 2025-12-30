import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_read_receipt.freezed.dart';
part 'message_read_receipt.g.dart';

/// Represents a read receipt for a message
@freezed
class MessageReadReceipt with _$MessageReadReceipt {
  const factory MessageReadReceipt({
    required String id,
    required String messageId,
    required String alumnusId,
    required DateTime readAt,
    // Extended info
    String? alumnusName,
  }) = _MessageReadReceipt;

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) =>
      _$MessageReadReceiptFromJson(json);

  /// Create MessageReadReceipt from Supabase JSON (snake_case)
  static MessageReadReceipt fromSupabaseJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      alumnusId: json['alumnus_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
      alumnusName: json['alumnus_name'] as String?,
    );
  }
}
