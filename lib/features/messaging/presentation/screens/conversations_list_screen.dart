import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../globe/presentation/providers/globe_provider.dart';
import '../../domain/models/conversation.dart';
import '../providers/messaging_provider.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

/// Main conversations list screen showing all user's conversations
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(userConversationsProvider);
    final unreadCountAsync = ref.watch(totalUnreadCountProvider);

    // Get current user's location to check country validity
    final authState = ref.watch(authStateProvider);
    String? currentAlumnusId;
    authState.whenData((state) {
      state.maybeWhen(
        authenticated: (user, alumnusId) => currentAlumnusId = alumnusId,
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(
              'assets/images/Baret.png',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 80,
          actions: [
            // Unread count badge
            unreadCountAsync.when(
              data: (count) => count > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading conversations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userConversationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          // Filter conversations based on current user's country
          final filteredConversations = currentAlumnusId != null
              ? _filterConversationsByCountry(
                  ref,
                  currentAlumnusId!,
                  conversations,
                )
              : conversations;

          if (filteredConversations.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(userConversationsProvider.notifier).refresh();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredConversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = filteredConversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          conversationId: conversation.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewConversationScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Conversations Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start chatting with fellow Baret Scholars alumni from around the world',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewConversationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Start New Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter conversations based on current user's country validity
  /// Hides country groups when user's country is N/A, Unknown, or invalid
  List<Conversation> _filterConversationsByCountry(
    WidgetRef ref,
    String alumnusId,
    List<Conversation> conversations,
  ) {
    // Get current user's location
    final locationAsync = ref.watch(currentUserLocationProvider(alumnusId));

    return locationAsync.when(
      data: (location) {
        final currentCountry = location?.country;
        final hasInvalidCountry = currentCountry == null ||
            currentCountry == 'N/A' ||
            currentCountry == 'Unknown' ||
            currentCountry.isEmpty;

        if (!hasInvalidCountry) {
          return conversations; // Show all if country is valid
        }

        // Filter out country-type conversations when country is invalid
        return conversations.where((conv) {
          return conv.type != ConversationType.country;
        }).toList();
      },
      loading: () => conversations, // Show all while loading
      error: (_, __) => conversations, // Show all on error
    );
  }
}

/// Individual conversation tile in the list
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildAvatar(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _getConversationTitle(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              timeago.format(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      subtitle: conversation.lastMessagePreview != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                conversation.lastMessagePreview!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      trailing: conversation.unreadCount != null && conversation.unreadCount! > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount! > 9 ? '9+' : '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAvatar() {
    IconData icon;
    Color color;

    switch (conversation.type) {
      case ConversationType.direct:
        icon = Icons.person;
        color = AppColors.primary;
        break;
      case ConversationType.group:
        icon = Icons.group;
        color = Colors.purple;
        break;
      case ConversationType.cohort:
        icon = Icons.school;
        color = Colors.orange;
        break;
      case ConversationType.country:
        icon = Icons.public;
        color = Colors.green;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  String _getConversationTitle() {
    if (conversation.name != null && conversation.name!.isNotEmpty) {
      return conversation.name!;
    }

    switch (conversation.type) {
      case ConversationType.direct:
        // For DMs, show the other person's name (from members)
        if (conversation.members.isNotEmpty) {
          return conversation.members.first.alumnusName ?? 'Direct Message';
        }
        return 'Direct Message';
      case ConversationType.cohort:
        return 'Cohort ${conversation.cohortYear ?? ""} Group';
      case ConversationType.country:
        return '${conversation.countryCode ?? "Country"} Group';
      case ConversationType.group:
        return 'Group Chat';
    }
  }
}
