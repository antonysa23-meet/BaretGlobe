import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/messaging_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'messaging_provider.g.dart';

// ==================
// REPOSITORY PROVIDER
// ==================

/// Provider for messaging repository
@riverpod
MessagingRepository messagingRepository(MessagingRepositoryRef ref) {
  return MessagingRepository();
}

// ==================
// CONVERSATIONS
// ==================

/// Provider for all conversations for current user with real-time updates
@riverpod
class UserConversations extends _$UserConversations {
  @override
  Future<List<Conversation>> build() async {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) {
          if (alumnusId == null) return Future.value([]);

          // Subscribe to real-time changes
          _subscribeToChanges(alumnusId);

          // Fetch initial data
          return _fetchConversations(alumnusId);
        },
        orElse: () async => [],
      ),
      loading: () async => [],
      error: (_, __) async => [],
    );
  }

  Future<List<Conversation>> _fetchConversations(String alumnusId) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      print('🔵 MessagingProvider: Fetching conversations for $alumnusId');
      final conversations = await repository.getConversations(alumnusId);
      print('✅ MessagingProvider: Got ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('❌ MessagingProvider: Error fetching conversations - $e');
      throw Exception('Failed to load conversations: $e');
    }
  }

  void _subscribeToChanges(String alumnusId) {
    final repository = ref.read(messagingRepositoryProvider);

    // Listen to real-time conversation updates from Supabase
    repository.subscribeToConversations(alumnusId).listen((conversations) {
      state = AsyncValue.data(conversations);
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  /// Refresh conversations manually
  Future<void> refresh() async {
    final authState = ref.read(authStateProvider);

    await authState.when(
      data: (authData) => authData.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return;

          state = const AsyncValue.loading();
          state = await AsyncValue.guard(() => _fetchConversations(alumnusId));
        },
        orElse: () async {},
      ),
      loading: () async {},
      error: (_, __) async {},
    );
  }
}

// ==================
// MESSAGES IN CONVERSATION
// ==================

/// Provider for messages in a specific conversation with real-time updates
@riverpod
class ConversationMessages extends _$ConversationMessages {
  @override
  Future<List<Message>> build(String conversationId) async {
    // Subscribe to real-time changes
    _subscribeToChanges(conversationId);

    // Fetch initial data
    return _fetchMessages(conversationId);
  }

  Future<List<Message>> _fetchMessages(String conversationId) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      print('🔵 MessagingProvider: Fetching messages for conversation $conversationId');
      final messages = await repository.getMessages(
        conversationId: conversationId,
        limit: 50,
      );
      print('✅ MessagingProvider: Got ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ MessagingProvider: Error fetching messages - $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  void _subscribeToChanges(String conversationId) {
    final repository = ref.read(messagingRepositoryProvider);

    // Listen to real-time message updates from Supabase
    repository.subscribeToMessages(conversationId).listen((messages) {
      state = AsyncValue.data(messages);
    }, onError: (error) {
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  /// Load more messages (pagination)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AsyncData<List<Message>>) return;

    final currentMessages = currentState.value;
    if (currentMessages.isEmpty) return;

    final oldestMessage = currentMessages.last;
    final repository = ref.read(messagingRepositoryProvider);

    try {
      final olderMessages = await repository.getMessages(
        conversationId: conversationId,
        limit: 50,
        before: oldestMessage.createdAt,
      );

      if (olderMessages.isNotEmpty) {
        state = AsyncValue.data([...currentMessages, ...olderMessages]);
      }
    } catch (e) {
      print('❌ MessagingProvider: Error loading more messages - $e');
    }
  }

  /// Refresh messages manually
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMessages(conversationId));
  }
}

// ==================
// UNREAD COUNT
// ==================

/// Provider for total unread message count for current user
@riverpod
class TotalUnreadCount extends _$TotalUnreadCount {
  @override
  Future<int> build() async {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return 0;

          // Listen to conversation changes to update unread count
          ref.listen(userConversationsProvider, (previous, next) {
            // When conversations update, refresh unread count
            refresh();
          });

          return _fetchUnreadCount(alumnusId);
        },
        orElse: () async => 0,
      ),
      loading: () async => 0,
      error: (_, __) async => 0,
    );
  }

  Future<int> _fetchUnreadCount(String alumnusId) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      final count = await repository.getTotalUnreadCount(alumnusId);
      print('🔵 MessagingProvider: Total unread count: $count');
      return count;
    } catch (e) {
      print('❌ MessagingProvider: Error fetching unread count - $e');
      return 0;
    }
  }

  /// Refresh unread count manually
  Future<void> refresh() async {
    final authState = ref.read(authStateProvider);

    await authState.when(
      data: (authData) => authData.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return;

          state = const AsyncValue.loading();
          state = await AsyncValue.guard(() => _fetchUnreadCount(alumnusId));
        },
        orElse: () async {},
      ),
      loading: () async {},
      error: (_, __) async {},
    );
  }
}

// ==================
// CONVERSATION ACTIONS
// ==================

/// Provider for conversation actions (create, start DM, send message, etc.)
@riverpod
class ConversationActions extends _$ConversationActions {
  @override
  void build() {
    // No state needed, just actions
  }

  /// Start a direct message conversation with another user
  /// Returns the conversation ID
  Future<String> startDirectMessage(String otherUserId) async {
    final authState = ref.read(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) {
            throw Exception('No alumnus profile found');
          }

          final repository = ref.read(messagingRepositoryProvider);
          try {
            print('🔵 MessagingProvider: Starting DM with $otherUserId');
            final conversationId = await repository.getOrCreateDirectConversation(
              currentUserId: alumnusId,
              otherUserId: otherUserId,
            );
            print('✅ MessagingProvider: DM conversation ID: $conversationId');

            // Refresh conversations list
            ref.invalidate(userConversationsProvider);

            return conversationId;
          } catch (e) {
            print('❌ MessagingProvider: Error starting DM - $e');
            throw Exception('Failed to start conversation: $e');
          }
        },
        orElse: () async => throw Exception('Not authenticated'),
      ),
      loading: () async => throw Exception('Not authenticated'),
      error: (_, __) async => throw Exception('Not authenticated'),
    );
  }

  /// Create a custom group conversation
  /// Returns the created Conversation
  Future<Conversation> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    final authState = ref.read(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) {
            throw Exception('No alumnus profile found');
          }

          final repository = ref.read(messagingRepositoryProvider);
          try {
            print('🔵 MessagingProvider: Creating group "$name" with ${memberIds.length} members');
            final conversation = await repository.createGroupConversation(
              creatorId: alumnusId,
              name: name,
              memberIds: memberIds,
            );
            print('✅ MessagingProvider: Created group: ${conversation.id}');

            // Refresh conversations list
            ref.invalidate(userConversationsProvider);

            return conversation;
          } catch (e) {
            print('❌ MessagingProvider: Error creating group - $e');
            throw Exception('Failed to create group: $e');
          }
        },
        orElse: () async => throw Exception('Not authenticated'),
      ),
      loading: () async => throw Exception('Not authenticated'),
      error: (_, __) async => throw Exception('Not authenticated'),
    );
  }

  /// Send a message to a conversation
  /// Returns the created Message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final authState = ref.read(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) {
            throw Exception('No alumnus profile found');
          }

          final repository = ref.read(messagingRepositoryProvider);
          try {
            print('🔵 MessagingProvider: Sending message to $conversationId');
            final message = await repository.sendMessage(
              conversationId: conversationId,
              senderId: alumnusId,
              content: content,
            );
            print('✅ MessagingProvider: Message sent: ${message.id}');

            // Messages will auto-update via real-time subscription
            // But also invalidate to ensure fresh data
            ref.invalidate(conversationMessagesProvider(conversationId));
            ref.invalidate(userConversationsProvider);

            return message;
          } catch (e) {
            print('❌ MessagingProvider: Error sending message - $e');
            throw Exception('Failed to send message: $e');
          }
        },
        orElse: () async => throw Exception('Not authenticated'),
      ),
      loading: () async => throw Exception('Not authenticated'),
      error: (_, __) async => throw Exception('Not authenticated'),
    );
  }

  /// Mark messages in a conversation as read
  Future<void> markAsRead(String conversationId) async {
    final authState = ref.read(authStateProvider);

    await authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return;

          final repository = ref.read(messagingRepositoryProvider);
          try {
            print('🔵 MessagingProvider: Marking conversation $conversationId as read');
            await repository.markAsRead(
              conversationId: conversationId,
              alumnusId: alumnusId,
            );
            print('✅ MessagingProvider: Marked as read');

            // Refresh unread count
            ref.invalidate(totalUnreadCountProvider);
            ref.invalidate(userConversationsProvider);
          } catch (e) {
            print('❌ MessagingProvider: Error marking as read - $e');
          }
        },
        orElse: () async {},
      ),
      loading: () async {},
      error: (_, __) async {},
    );
  }

  /// Add member to a conversation (custom groups only)
  Future<void> addMember({
    required String conversationId,
    required String alumnusId,
  }) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      print('🔵 MessagingProvider: Adding member $alumnusId to conversation $conversationId');
      await repository.addMemberToConversation(
        conversationId: conversationId,
        alumnusId: alumnusId,
      );
      print('✅ MessagingProvider: Member added');

      // Refresh conversations
      ref.invalidate(userConversationsProvider);
    } catch (e) {
      print('❌ MessagingProvider: Error adding member - $e');
      throw Exception('Failed to add member: $e');
    }
  }

  /// Leave a conversation
  Future<void> leaveConversation(String conversationId) async {
    final authState = ref.read(authStateProvider);

    await authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return;

          final repository = ref.read(messagingRepositoryProvider);
          try {
            print('🔵 MessagingProvider: Leaving conversation $conversationId');
            await repository.leaveConversation(
              conversationId: conversationId,
              alumnusId: alumnusId,
            );
            print('✅ MessagingProvider: Left conversation');

            // Refresh conversations list
            ref.invalidate(userConversationsProvider);
          } catch (e) {
            print('❌ MessagingProvider: Error leaving conversation - $e');
            throw Exception('Failed to leave conversation: $e');
          }
        },
        orElse: () async {},
      ),
      loading: () async {},
      error: (_, __) async {},
    );
  }
}

// ==================
// SEARCH ALUMNI
// ==================

/// Provider for searching alumni by name or cohort
@riverpod
class SearchAlumni extends _$SearchAlumni {
  @override
  Future<List<Map<String, dynamic>>> build({
    String? query,
    int? cohortYear,
  }) async {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) => state.maybeWhen(
        authenticated: (user, alumnusId) async {
          if (alumnusId == null) return [];

          return _searchAlumni(
            currentUserId: alumnusId,
            query: query,
            cohortYear: cohortYear,
          );
        },
        orElse: () async => [],
      ),
      loading: () async => [],
      error: (_, __) async => [],
    );
  }

  Future<List<Map<String, dynamic>>> _searchAlumni({
    required String currentUserId,
    String? query,
    int? cohortYear,
  }) async {
    final repository = ref.read(messagingRepositoryProvider);
    try {
      print('🔵 MessagingProvider: Searching alumni with query: $query, cohort: $cohortYear');
      final results = await repository.searchAlumni(
        currentUserId: currentUserId,
        query: query,
        cohortYear: cohortYear,
      );
      print('✅ MessagingProvider: Found ${results.length} alumni');
      return results;
    } catch (e) {
      print('❌ MessagingProvider: Error searching alumni - $e');
      return [];
    }
  }

  /// Update search parameters
  void updateSearch({String? query, int? cohortYear}) {
    ref.invalidateSelf();
  }
}
