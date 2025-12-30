import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/messaging_provider.dart';
import 'chat_screen.dart';

/// Screen for creating new conversations (DM or group)
class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  // For group creation
  final Set<String> _selectedAlumniIds = {};
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _startDirectMessage(String otherUserId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final conversationId = await ref
          .read(conversationActionsProvider.notifier)
          .startDirectMessage(otherUserId);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversationId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedAlumniIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final conversation = await ref
          .read(conversationActionsProvider.notifier)
          .createGroupConversation(
            name: _groupNameController.text.trim(),
            memberIds: _selectedAlumniIds.toList(),
          );

      if (mounted) {
        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              conversationName: conversation.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Conversation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Direct Message'),
            Tab(text: 'Create Group'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectMessageTab(),
          _buildCreateGroupTab(),
        ],
      ),
    );
  }

  Widget _buildDirectMessageTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Alumni list
        Expanded(
          child: _buildAlumniList(
            isMultiSelect: false,
            onAlumnusTap: (alumnusId) => _startDirectMessage(alumnusId),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGroupTab() {
    return Column(
      children: [
        // Group name input
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: 'Group Name',
              prefixIcon: const Icon(Icons.group),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Selected count
        if (_selectedAlumniIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_selectedAlumniIds.length} member(s) selected',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Alumni list (multi-select)
        Expanded(
          child: _buildAlumniList(
            isMultiSelect: true,
            onAlumnusTap: (alumnusId) {
              setState(() {
                if (_selectedAlumniIds.contains(alumnusId)) {
                  _selectedAlumniIds.remove(alumnusId);
                } else {
                  _selectedAlumniIds.add(alumnusId);
                }
              });
            },
          ),
        ),

        // Create button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingGroup ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreatingGroup
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlumniList({
    required bool isMultiSelect,
    required Function(String) onAlumnusTap,
  }) {
    final searchAsync = ref.watch(
      searchAlumniProvider(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      ),
    );

    return searchAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading alumni'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (alumni) {
        if (alumni.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No alumni found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: alumni.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final alumnus = alumni[index];
            final alumnusId = alumnus['id'] as String;
            final name = alumnus['name'] as String;
            final cohortYear = alumnus['cohort_year'] as int?;
            final cohortRegion = alumnus['cohort_region'] as String?;
            final profileImageUrl = alumnus['profile_image_url'] as String?;

            final isSelected = _selectedAlumniIds.contains(alumnusId);

            return ListTile(
              onTap: () => onAlumnusTap(alumnusId),
              leading: profileImageUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(profileImageUrl),
                    )
                  : CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                cohortYear != null
                    ? 'Cohort $cohortYear${cohortRegion != null ? " · $cohortRegion" : ""}'
                    : cohortRegion ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: isMultiSelect
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => onAlumnusTap(alumnusId),
                      activeColor: AppColors.primary,
                    )
                  : const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }
}
