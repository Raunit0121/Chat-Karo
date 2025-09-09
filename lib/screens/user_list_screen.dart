import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import 'profile_edit_screen.dart';
import '../services/auth_service.dart';
import '../widgets/user_tile.dart';
import '../models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'call_history_screen.dart';

class UserListScreen extends StatefulWidget {
  UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GroupService _groupService = GroupService();
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0 for chats, 1 for groups

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          children: [
            // Background circles
            Positioned(
              left: -100,
              top: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -120,
              bottom: -60,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                // Custom AppBar
                Container(
                  padding: const EdgeInsets.only(
                    top: 40,
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Chat Karo',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Spacer(),
                      if (userName != null && userName.isNotEmpty) ...[
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      StreamBuilder<UserModel?>(
                        stream: AuthService().getCurrentUserStream(),
                        builder: (context, snapshot) {
                          final currentUser = snapshot.data;
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ProfileEditScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.lightGray,
                                backgroundImage:
                                    currentUser?.photoUrl.isNotEmpty == true
                                        ? NetworkImage(currentUser!.photoUrl)
                                        : null,
                                child:
                                    currentUser?.photoUrl.isEmpty != false
                                        ? const Icon(
                                          Icons.person,
                                          color: AppColors.primaryBlue,
                                          size: 20,
                                        )
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Search Box
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGray,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.darkText,
                    tabs: const [
                      Tab(icon: Icon(Icons.chat), text: 'Chats'),
                      Tab(icon: Icon(Icons.group), text: 'Groups'),
                      Tab(icon: Icon(Icons.call), text: 'Calls'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Individual Chats Tab
                      StreamBuilder<List<UserModel>>(
                        stream: ChatService().getUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: \\${snapshot.error}'),
                            );
                          }
                          final users = snapshot.data ?? [];
                          final filteredUsers =
                              _searchQuery.isEmpty
                                  ? users
                                  : users
                                      .where(
                                        (u) => u.name.toLowerCase().contains(
                                          _searchQuery,
                                        ),
                                      )
                                      .toList();
                          if (filteredUsers.isEmpty) {
                            return const Center(child: Text('No users found'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            itemCount: filteredUsers.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return StreamBuilder<int>(
                                stream: ChatService().getUnreadCount(user.uid),
                                builder: (context, unreadSnapshot) {
                                  final unreadCount = unreadSnapshot.data ?? 0;
                                  return StreamBuilder<MessageModel?>(
                                    stream: ChatService().getLastMessage(
                                      user.uid,
                                    ),
                                    builder: (context, snapshot) {
                                      final msg = snapshot.data;
                                      return Material(
                                        elevation: 2,
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.white,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/chat',
                                              arguments: user,
                                            );
                                          },
                                          child: UserTile(
                                            user: user,
                                            lastMessage: msg?.text,
                                            lastMessageTime: msg?.timestamp,
                                            unreadCount: unreadCount,
                                            onTap: null, // handled by InkWell
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      // Groups Tab
                      StreamBuilder<List<GroupModel>>(
                        stream: _groupService.getUserGroups(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 48,
                                    color: AppColors.primaryBlue,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Setting up groups...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Firebase indexes are building.\nThis usually takes 2-5 minutes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.lightGray,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  CircularProgressIndicator(
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                            );
                          }

                          final groups = snapshot.data ?? [];
                          return _buildGroupsList(groups);
                        },
                      ),
                      // Calls Tab
                      const CallHistoryScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.accentBlue,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );
          },
          child: const Icon(Icons.group_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: AppColors.lightGray),
            SizedBox(height: 16),
            Text(
              'No groups yet',
              style: TextStyle(fontSize: 18, color: AppColors.lightGray),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to create a group',
              style: TextStyle(fontSize: 14, color: AppColors.lightGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primaryBlue,
              backgroundImage:
                  group.profilePicture != null
                      ? NetworkImage(group.profilePicture!)
                      : null,
              child:
                  group.profilePicture == null
                      ? Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                      : null,
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              '${group.memberCount} members',
              style: const TextStyle(color: AppColors.lightGray, fontSize: 14),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.lightGray,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(group: group),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
