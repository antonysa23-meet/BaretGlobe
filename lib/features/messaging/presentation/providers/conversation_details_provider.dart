import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/conversation_member.dart';
import 'messaging_provider.dart';

part 'conversation_details_provider.g.dart';

// ==================
// CONVERSATION DETAILS
// ==================

/// Provider for fetching and managing conversation details with members
@riverpod
class ConversationDetails extends _$ConversationDetails {
  @override
  Future<ConversationDetailsData?> build(String conversationId) async {
    return _fetchConversationDetails(conversationId);
  }

  Future<ConversationDetailsData?> _fetchConversationDetails(
      String conversationId) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      print(
          '🔵 ConversationDetailsProvider: Fetching conversation $conversationId');

      // Fetch conversation
      final conversation = await repository.getConversation(conversationId);
      if (conversation == null) {
        print('❌ ConversationDetailsProvider: Conversation not found');
        return null;
      }

      // Fetch members
      final members = await repository.getConversationMembers(conversationId);
      print('✅ ConversationDetailsProvider: Got ${members.length} members');

      return ConversationDetailsData(
        conversation: conversation,
        members: members,
      );
    } catch (e) {
      print('❌ ConversationDetailsProvider: Error fetching details - $e');
      throw Exception('Failed to load conversation details: $e');
    }
  }

  /// Refresh conversation details manually
  Future<void> refresh() async {
    // Re-fetch by invalidating self - this will re-run build() with the same conversationId
    ref.invalidateSelf();
  }
}

/// Data class to hold conversation and its members
class ConversationDetailsData {
  final Conversation conversation;
  final List<ConversationMember> members;

  ConversationDetailsData({
    required this.conversation,
    required this.members,
  });

  /// Get active members (not left)
  List<ConversationMember> get activeMembers =>
      members.where((m) => m.leftAt == null).toList();

  /// Check if a specific member is the creator
  bool isCreator(String alumnusId) => conversation.createdBy == alumnusId;

  /// Get the other person in a direct message
  ConversationMember? getOtherPersonInDM(String currentUserId) {
    if (conversation.type != ConversationType.direct) return null;
    return activeMembers.firstWhere(
      (m) => m.alumnusId != currentUserId,
      orElse: () => activeMembers.first,
    );
  }
}
