import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'profile_edit_screen.dart';
import '../services/auth_service.dart';
import '../widgets/user_tile.dart';
import '../models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserListScreen extends StatefulWidget {
  UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    return Scaffold(
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
                padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 24),
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
                      'Chats',
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
                    IconButton(
                      icon: const Icon(Icons.account_circle, color: AppColors.primaryBlue),
                      tooltip: 'Edit Profile',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: ChatService().getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: \\${snapshot.error}'));
                    }
                    final users = snapshot.data ?? [];
                    final filteredUsers = _searchQuery.isEmpty
                        ? users
                        : users.where((u) => u.name.toLowerCase().contains(_searchQuery)).toList();
                    if (filteredUsers.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return StreamBuilder<int>(
                          stream: ChatService().getUnreadCount(user.uid),
                          builder: (context, unreadSnapshot) {
                            final unreadCount = unreadSnapshot.data ?? 0;
                            return StreamBuilder<MessageModel?>(
                              stream: ChatService().getLastMessage(user.uid),
                              builder: (context, snapshot) {
                                final msg = snapshot.data;
                                return Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
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
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentBlue,
        onPressed: () {
          // TODO: Start new chat
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
} 