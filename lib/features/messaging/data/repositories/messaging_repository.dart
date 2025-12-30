import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/conversation_member.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_read_receipt.dart';

/// Repository for messaging operations
class MessagingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================
  // CONVERSATION METHODS
  // ==================

  /// Get all conversations for current user, sorted by last message
  Future<List<Conversation>> getConversations(String alumnusId) async {
    try {
      final response = await _supabase.rpc(
        ApiConstants.getUserConversationsFunction,
        params: {'p_alumnus_id': alumnusId},
      );

      return (response as List)
          .map((json) => Conversation.fromSupabaseJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Get or create a direct conversation with another user
  Future<String> getOrCreateDirectConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final conversationId = await _supabase.rpc(
        ApiConstants.getOrCreateDirectConversationFunction,
        params: {
          'p_user1_id': currentUserId,
          'p_user2_id': otherUserId,
        },
      );

      return conversationId as String;
    } catch (e) {
      print('❌ Error getting/creating direct conversation: $e');
      rethrow;
    }
  }

  /// Create a custom group conversation
  Future<Conversation> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      // Create conversation
      final conversationResponse = await _supabase
          .from(ApiConstants.conversationsTable)
          .insert({
            'type': 'group',
            'name': name,
            'created_by': creatorId,
          })
          .select()
          .single();

      final conversationId = conversationResponse['id'] as String;

      // Add creator and members
      final allMemberIds = {creatorId, ...memberIds}.toList();
      await _supabase.from(ApiConstants.conversationMembersTable).insert(
            allMemberIds
                .map((id) => {
                      'conversation_id': conversationId,
                      'alumnus_id': id,
                    })
                .toList(),
          );

      return Conversation.fromSupabaseJson(conversationResponse);
    } catch (e) {
      print('❌ Error creating group conversation: $e');
      rethrow;
    }
  }

  /// Get conversation by ID with members
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.conversationsTable)
          .select('*, conversation_members(*)')
          .eq('id', conversationId)
          .maybeSingle();

      if (response == null) return null;

      final conversation = Conversation.fromSupabaseJson(response);

      // Parse members
      final membersJson = response['conversation_members'] as List?;
      if (membersJson != null) {
        final members = membersJson
            .map((json) => ConversationMember.fromSupabaseJson(json))
            .toList();
        return conversation.copyWith(members: members);
      }

      return conversation;
    } catch (e) {
      print('❌ Error getting conversation: $e');
      rethrow;
    }
  }

  /// Get conversation members with alumnus details
  Future<List<ConversationMember>> getConversationMembers(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from(ApiConstants.conversationMembersTable)
          .select('''
          *,
          alumni:alumnus_id (
            id,
            name,
            cohort_year,
            profile_image_url
          )
        ''')
          .eq('conversation_id', conversationId)
          .isFilter('left_at', null);

      return (response as List).map((json) {
        final alumnus = json['alumni'];
        return ConversationMember.fromSupabaseJson({
          ...json,
          'alumnus_name': alumnus['name'],
          'alumnus_cohort_year': alumnus['cohort_year'],
          'alumnus_profile_image_url': alumnus['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting conversation members: $e');
      rethrow;
    }
  }

  /// Add member to conversation
  Future<void> addMemberToConversation({
    required String conversationId,
    required String alumnusId,
  }) async {
    try {
      await _supabase.from(ApiConstants.conversationMembersTable).insert({
        'conversation_id': conversationId,
        'alumnus_id': alumnusId,
      });
    } catch (e) {
      print('❌ Error adding member to conversation: $e');
      rethrow;
    }
  }

  /// Leave conversation
  Future<void> leaveConversation({
    required String conversationId,
    required String alumnusId,
  }) async {
    try {
      await _supabase
          .from(ApiConstants.conversationMembersTable)
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('alumnus_id', alumnusId);
    } catch (e) {
      print('❌ Error leaving conversation: $e');
      rethrow;
    }
  }

  // ==================
  // MESSAGE METHODS
  // ==================

  /// Get messages in a conversation with pagination
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final baseQuery = _supabase
          .from(ApiConstants.messagesTable)
          .select('''
          *,
          sender:sender_id (
            id,
            name,
            profile_image_url
          )
        ''')
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null);

      // Build final query with optional time filter
      final response = before != null
          ? await baseQuery
              .lt('created_at', before.toIso8601String())
              .order('created_at', ascending: false)
              .limit(limit)
          : await baseQuery
              .order('created_at', ascending: false)
              .limit(limit);

      return (response as List).map((json) {
        final sender = json['sender'];
        return Message.fromSupabaseJson({
          ...json,
          'sender_name': sender['name'],
          'sender_profile_image_url': sender['profile_image_url'],
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting messages: $e');
      rethrow;
    }
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.messagesTable)
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'content': content,
          })
          .select('''
          *,
          sender:sender_id (
            id,
            name,
            profile_image_url
          )
        ''')
          .single();

      final sender = response['sender'];
      return Message.fromSupabaseJson({
        ...response,
        'sender_name': sender['name'],
        'sender_profile_image_url': sender['profile_image_url'],
      });
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead({
    required String conversationId,
    required String alumnusId,
  }) async {
    try {
      // Update last_read_at in conversation_members
      await _supabase
          .from(ApiConstants.conversationMembersTable)
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('alumnus_id', alumnusId);

      // Get last read timestamp
      final member = await _supabase
          .from(ApiConstants.conversationMembersTable)
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .eq('alumnus_id', alumnusId)
          .single();

      final lastReadAt = member['last_read_at'] as String;

      // Get unread messages
      final unreadMessages = await _supabase
          .from(ApiConstants.messagesTable)
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', alumnusId)
          .gt('created_at', lastReadAt);

      // Create read receipts for unread messages
      if ((unreadMessages as List).isNotEmpty) {
        await _supabase.from(ApiConstants.messageReadReceiptsTable).insert(
              unreadMessages
                  .map((msg) => {
                        'message_id': msg['id'],
                        'alumnus_id': alumnusId,
                      })
                  .toList(),
            );
      }
    } catch (e) {
      print('❌ Error marking as read: $e');
      rethrow;
    }
  }

  /// Get read receipts for a message
  Future<List<MessageReadReceipt>> getReadReceipts(String messageId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.messageReadReceiptsTable)
          .select('''
          *,
          alumni:alumnus_id (name)
        ''')
          .eq('message_id', messageId);

      return (response as List).map((json) {
        return MessageReadReceipt.fromSupabaseJson({
          ...json,
          'alumnus_name': json['alumni']['name'],
        });
      }).toList();
    } catch (e) {
      print('❌ Error getting read receipts: $e');
      rethrow;
    }
  }

  /// Get total unread count for user
  Future<int> getTotalUnreadCount(String alumnusId) async {
    try {
      final response = await _supabase.rpc(
        ApiConstants.getTotalUnreadCountFunction,
        params: {'p_alumnus_id': alumnusId},
      );

      return response as int;
    } catch (e) {
      print('❌ Error getting total unread count: $e');
      return 0;
    }
  }

  // ==================
  // REALTIME SUBSCRIPTIONS
  // ==================

  /// Subscribe to conversation list changes
  Stream<List<Conversation>> subscribeToConversations(String alumnusId) {
    return _supabase
        .from(ApiConstants.conversationMembersTable)
        .stream(primaryKey: ['id'])
        .eq('alumnus_id', alumnusId)
        .asyncMap((_) => getConversations(alumnusId));
  }

  /// Subscribe to messages in a conversation
  Stream<List<Message>> subscribeToMessages(String conversationId) {
    return _supabase
        .from(ApiConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(50)
        .asyncMap((data) async {
      // Fetch with sender details
      return await getMessages(conversationId: conversationId);
    });
  }

  /// Subscribe to new messages notification
  Stream<Message> subscribeToNewMessages(String alumnusId) {
    return _supabase
        .from(ApiConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .asyncExpand((messages) async* {
      for (final msgJson in messages) {
        final message = Message.fromSupabaseJson(msgJson);

        // Only emit if user is in conversation and not the sender
        if (message.senderId != alumnusId) {
          final members = await getConversationMembers(message.conversationId);
          if (members.any((m) => m.alumnusId == alumnusId)) {
            yield message;
          }
        }
      }
    });
  }

  // ==================
  // SEARCH
  // ==================

  /// Search alumni by name or cohort for messaging
  Future<List<Map<String, dynamic>>> searchAlumni({
    required String currentUserId,
    String? query,
    int? cohortYear,
  }) async {
    try {
      final baseQuery = _supabase
          .from(ApiConstants.alumniTable)
          .select('id, name, cohort_year, cohort_region, profile_image_url')
          .neq('id', currentUserId);

      // Build query based on filters
      final response = await (() {
        var q = baseQuery;

        if (query != null && query.isNotEmpty) {
          q = q.ilike('name', '%$query%');
        }

        if (cohortYear != null) {
          q = q.eq('cohort_year', cohortYear);
        }

        return q.order('name');
      })();

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error searching alumni: $e');
      return [];
    }
  }
}
