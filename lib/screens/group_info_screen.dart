import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/chat_service.dart';
// import 'add_members_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;

  const GroupInfoScreen({super.key, required this.group});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupService _groupService = GroupService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  GroupModel? _currentGroup;
  List<UserModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  void _loadGroupData() async {
    try {
      final group = await _groupService.getGroup(widget.group.id);
      if (group != null) {
        setState(() {
          _currentGroup = group;
        });

        // Load member details
        final memberDetails = <UserModel>[];
        for (final memberId in group.members) {
          final user = await _chatService.getUserById(memberId);
          if (user != null) {
            memberDetails.add(user);
          }
        }

        setState(() {
          _members = memberDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading group info: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _currentGroup == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Info'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isAdmin = _currentGroup!.isAdmin(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Group'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Group Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete Group',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Group header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                _currentGroup!.profilePicture != null
                                    ? NetworkImage(
                                      _currentGroup!.profilePicture!,
                                    )
                                    : null,
                            child:
                                _currentGroup!.profilePicture == null
                                    ? Text(
                                      _currentGroup!.name.isNotEmpty
                                          ? _currentGroup!.name[0].toUpperCase()
                                          : 'G',
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentGroup!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentGroup!.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _currentGroup!.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Created ${_formatDate(_currentGroup!.createdAt)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Members section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Members (${_currentGroup!.memberCount})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              if (_currentGroup!.canAddMembers(currentUser.uid))
                                IconButton(
                                  onPressed: _addMembers,
                                  icon: const Icon(
                                    Icons.person_add,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              final member = _members[index];
                              final isCurrentUser =
                                  member.uid == currentUser.uid;
                              final isMemberAdmin = _currentGroup!.isAdmin(
                                member.uid,
                              );

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      member.photoUrl.isNotEmpty
                                          ? NetworkImage(member.photoUrl)
                                          : null,
                                  child:
                                      member.photoUrl.isEmpty
                                          ? Text(
                                            member.name.isNotEmpty
                                                ? member.name[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isCurrentUser ? 'You' : member.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isMemberAdmin)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Admin',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(member.email),
                                trailing:
                                    isAdmin && !isCurrentUser
                                        ? PopupMenuButton<String>(
                                          onSelected:
                                              (action) => _handleMemberAction(
                                                action,
                                                member,
                                              ),
                                          itemBuilder:
                                              (context) => [
                                                if (!isMemberAdmin)
                                                  const PopupMenuItem(
                                                    value: 'make_admin',
                                                    child: Text('Make Admin'),
                                                  ),
                                                if (isMemberAdmin &&
                                                    _currentGroup!
                                                            .admins
                                                            .length >
                                                        1)
                                                  const PopupMenuItem(
                                                    value: 'remove_admin',
                                                    child: Text('Remove Admin'),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'remove',
                                                  child: Text(
                                                    'Remove from Group',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                        )
                                        : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Leave group button
                    if (!isAdmin || _currentGroup!.admins.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _leaveGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Leave Group'),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editGroup();
        break;
      case 'settings':
        _groupSettings();
        break;
      case 'delete':
        _deleteGroup();
        break;
    }
  }

  void _handleMemberAction(String action, UserModel member) async {
    try {
      switch (action) {
        case 'make_admin':
          await _groupService.makeAdmin(
            groupId: _currentGroup!.id,
            memberId: member.uid,
          );
          break;
        case 'remove_admin':
          await _groupService.removeAdmin(
            groupId: _currentGroup!.id,
            adminId: member.uid,
          );
          break;
        case 'remove':
          await _groupService.removeMember(
            groupId: _currentGroup!.id,
            memberId: member.uid,
          );
          break;
      }
      _loadGroupData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _addMembers() {
    // TODO: Implement add members screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add members coming soon!')));
  }

  void _editGroup() {
    // TODO: Implement edit group screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit group coming soon!')));
  }

  void _groupSettings() {
    // TODO: Implement group settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group settings coming soon!')),
    );
  }

  void _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Group'),
            content: const Text(
              'Are you sure you want to delete this group? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _groupService.deleteGroup(_currentGroup!.id);
        if (mounted) {
          Navigator.pop(context); // Go back to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting group: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _leaveGroup() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: const Text('Are you sure you want to leave this group?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _groupService.removeMember(
          groupId: _currentGroup!.id,
          memberId: currentUser.uid,
        );
        if (mounted) {
          Navigator.pop(context); // Go back to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left group successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving group: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
