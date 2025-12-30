import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/conversation.dart';
import '../providers/conversation_details_provider.dart';
import '../providers/messaging_provider.dart';
import '../widgets/member_list_tile.dart';

/// Conversation details screen showing members, metadata, and actions
class ConversationDetailsScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationDetailsScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationDetailsScreen> createState() =>
      _ConversationDetailsScreenState();
}

class _ConversationDetailsScreenState
    extends ConsumerState<ConversationDetailsScreen> {
  bool _isLeaving = false;
  final bool _isAddingMember = false;

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(conversationDetailsProvider(widget.conversationId));
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Details'),
        elevation: 0,
      ),
      body: detailsAsync.when(
        data: (data) {
          if (data == null) {
            return _buildErrorState('Conversation not found');
          }

          return authState.when(
            data: (auth) => auth.maybeWhen(
              authenticated: (user, alumnusId) {
                if (alumnusId == null) {
                  return _buildErrorState('Not authenticated');
                }
                return _buildContent(data, alumnusId);
              },
              orElse: () => _buildErrorState('Not authenticated'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState('Authentication error'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildContent(ConversationDetailsData data, String currentUserId) {
    final conversation = data.conversation;
    final activeMembers = data.activeMembers;
    final isCreator = data.isCreator(currentUserId);
    final isDirect = conversation.type == ConversationType.direct;
    final isGroup = conversation.type == ConversationType.group;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(conversationDetailsProvider(widget.conversationId).notifier)
            .refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section with type badge and metadata
          _buildHeader(conversation, data, currentUserId),
          const SizedBox(height: 24),

          // Members section
          _buildMembersSection(
            activeMembers,
            conversation,
            isCreator,
            isDirect,
          ),
          const SizedBox(height: 24),

          // Placeholder actions
          if (!isDirect) ...[
            _buildPlaceholderActions(),
            const SizedBox(height: 24),
          ],

          // Leave conversation button (groups only)
          if (isGroup) _buildLeaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    Conversation conversation,
    ConversationDetailsData data,
    String currentUserId,
  ) {
    final isDirect = conversation.type == ConversationType.direct;
    String title;
    String subtitle;

    if (isDirect) {
      final otherPerson = data.getOtherPersonInDM(currentUserId);
      title = otherPerson?.alumnusName ?? 'Unknown User';
      subtitle = otherPerson != null
          ? 'Class of ${otherPerson.alumnusCohortYear}'
          : 'Direct Message';
    } else {
      title = conversation.name ?? _getDefaultGroupName(conversation);
      subtitle = _getConversationSubtitle(conversation);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            _buildTypeBadge(conversation.type),
            const SizedBox(height: 12),

            // Conversation name/title
            Text(
              title,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 4),

            // Subtitle with metadata
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
            ),

            // Last message time
            if (conversation.lastMessageAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last message ${timeago.format(conversation.lastMessageAt!)}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ConversationType type) {
    String label;
    Color color;

    switch (type) {
      case ConversationType.direct:
        label = 'DIRECT MESSAGE';
        color = AppColors.primaryBlue;
        break;
      case ConversationType.group:
        label = 'CUSTOM GROUP';
        color = AppColors.secondarySage;
        break;
      case ConversationType.cohort:
        label = 'COHORT GROUP';
        color = AppColors.accentGold;
        break;
      case ConversationType.country:
        label = 'COUNTRY GROUP';
        color = AppColors.cohortColors[5]; // Purple
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: AppColors.white,
          fontSize: 11,
        ),
      ),
    );
  }

  String _getDefaultGroupName(Conversation conversation) {
    if (conversation.type == ConversationType.cohort) {
      return 'Class of ${conversation.cohortYear}';
    } else if (conversation.type == ConversationType.country) {
      return '${conversation.countryCode} Alumni';
    }
    return 'Group Chat';
  }

  String _getConversationSubtitle(Conversation conversation) {
    if (conversation.type == ConversationType.cohort) {
      return 'Cohort-wide conversation';
    } else if (conversation.type == ConversationType.country) {
      return 'Country-wide conversation';
    }
    return 'Created ${timeago.format(conversation.createdAt)}';
  }

  Widget _buildMembersSection(
    List members,
    Conversation conversation,
    bool isCreator,
    bool isDirect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Members (${members.length})',
              style: AppTextStyles.h4,
            ),
            if (isCreator && !isDirect)
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _isAddingMember ? null : _showAddMemberDialog,
                tooltip: 'Add Member',
                color: AppColors.secondarySage,
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Members list
        Card(
          child: members.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No members',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppColors.textGray.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isAdmin = member.alumnusId == conversation.createdBy;
                    return MemberListTile(
                      name: member.alumnusName ?? 'Unknown',
                      cohortYear: member.alumnusCohortYear ?? 2023,
                      isAdmin: isAdmin,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: AppTextStyles.h4,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.search, color: AppColors.textGray),
                title: Text(
                  'Search Messages',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'Coming soon',
                  style: AppTextStyles.caption,
                ),
                enabled: false,
              ),
              Divider(
                height: 1,
                color: AppColors.textGray.withValues(alpha: 0.2),
              ),
              const ListTile(
                leading:
                    Icon(Icons.notifications_off, color: AppColors.textGray),
                title: Text(
                  'Mute Notifications',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'Coming soon',
                  style: AppTextStyles.caption,
                ),
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLeaving ? null : _showLeaveDialog,
        icon: const Icon(Icons.exit_to_app),
        label: Text(_isLeaving ? 'Leaving...' : 'Leave Conversation'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(
            color: _isLeaving ? AppColors.textGray : AppColors.error,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Conversation?', style: AppTextStyles.h4),
        content: const Text(
          'Are you sure you want to leave this conversation? You will no longer receive messages.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveConversation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveConversation() async {
    setState(() => _isLeaving = true);

    try {
      await ref
          .read(conversationActionsProvider.notifier)
          .leaveConversation(widget.conversationId);

      if (!mounted) return;

      // Navigate back to conversations list (pop both details and chat screens)
      Navigator.of(context).pop(); // Pop details screen
      Navigator.of(context).pop(); // Pop chat screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left conversation successfully'),
          backgroundColor: AppColors.secondarySage,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLeaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave conversation: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member', style: AppTextStyles.h4),
        content: const Text(
          'Member search functionality coming soon. You will be able to search for alumni and add them to this conversation.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // TODO: Implement full add member dialog with search
    // Similar to new_conversation_screen.dart but filtering out existing members
    // Reference: lib/features/messaging/presentation/screens/new_conversation_screen.dart
  }
}
