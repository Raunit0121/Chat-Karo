import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/media_viewer.dart';
import '../widgets/typing_indicator.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isTyping = false;
  GroupModel? _currentGroup;
  List<MessageModel> _messages = [];
  bool _isLoadingMessages = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
    _loadGroupData();
    _loadMessages();
    _startMessageRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadGroupData() async {
    final group = await _groupService.getGroup(widget.group.id);
    if (group != null && mounted) {
      setState(() {
        _currentGroup = group;
      });
    }
  }

  void _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await _chatService.getGroupMessagesOnce(widget.group.id);
      if (mounted) {
        setState(() {
          // Sort newest first for reverse ListView (WhatsApp style)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _messages = messages;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  void _startMessageRefresh() {
    // Refresh messages every 3 seconds to simulate real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadMessages();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _currentGroup == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: () => _navigateToGroupInfo(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage:
                    _currentGroup!.profilePicture != null
                        ? NetworkImage(_currentGroup!.profilePicture!)
                        : null,
                child:
                    _currentGroup!.profilePicture == null
                        ? Text(
                          _currentGroup!.name.isNotEmpty
                              ? _currentGroup!.name[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentGroup!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_currentGroup!.memberCount} members',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 8),
                        Text('Group Info'),
                      ],
                    ),
                  ),
                  if (_currentGroup!.isAdmin(currentUser.uid))
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
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child:
                _isLoadingMessages
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? const Center(
                      child: Text(
                        'No messages yet.\nSend the first message!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.offlineGray,
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      reverse: true, // Show latest messages at bottom
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == currentUser.uid;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: EnhancedMessageBubble(
                            message: message,
                            isMe: isMe,
                            showSenderName:
                                !isMe, // Show sender name for group messages
                            onTap: () => _handleMessageTap(message),
                          ),
                        );
                      },
                    ),
          ),

          // Typing indicator
          StreamBuilder<bool>(
            stream: _chatService.getTypingStatus(_currentGroup!.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return const TypingIndicator(
                  isVisible: true,
                  userName: 'Someone',
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.lightGray)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showMediaOptions,
                  icon: const Icon(
                    Icons.attach_file,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTyping,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGray,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.primaryBlue,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _navigateToGroupInfo();
        break;
      case 'settings':
        _navigateToGroupSettings();
        break;
    }
  }

  void _navigateToGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupInfoScreen(group: _currentGroup!),
      ),
    ).then((_) => _loadGroupData()); // Refresh group data when returning
  }

  void _navigateToGroupSettings() {
    // TODO: Implement group settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group settings coming soon!')),
    );
  }

  void _handleTyping(String text) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(_currentGroup!.id, true);
    } else if (text.isEmpty && _isTyping) {
      _isTyping = false;
      _chatService.setTypingStatus(_currentGroup!.id, false);
    }
  }

  void _sendMessage() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || _currentGroup == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Check if user can send messages
    if (!_currentGroup!.canSendMessages(currentUser.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can send messages in this group'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    try {
      await _chatService.sendMessage(
        receiverId: _currentGroup!.id,
        text: text,
        groupId: _currentGroup!.id,
        isGroupMessage: true,
      );

      _messageController.clear();
      _isTyping = false;
      _chatService.setTypingStatus(_currentGroup!.id, false);

      // Refresh messages to show the new message
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Photo'),
                  onTap: () => _pickMedia(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Camera'),
                  onTap: () => _pickMedia(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.videocam,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Video'),
                  onTap: () => _pickVideo(),
                ),
              ],
            ),
          ),
    );
  }

  void _pickMedia(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet

    final currentUser = _authService.currentUser;
    if (currentUser == null || _currentGroup == null) return;

    // Check if user can send messages
    if (!_currentGroup!.canSendMessages(currentUser.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can send messages in this group'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        await _chatService.sendMediaMessage(
          receiverId: _currentGroup!.id,
          mediaFile: File(file.path),
          groupId: _currentGroup!.id,
          isGroupMessage: true,
        );

        // Refresh messages to show the new media message
        _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending media: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _pickVideo() async {
    Navigator.pop(context); // Close bottom sheet

    final currentUser = _authService.currentUser;
    if (currentUser == null || _currentGroup == null) return;

    // Check if user can send messages
    if (!_currentGroup!.canSendMessages(currentUser.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only admins can send messages in this group'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        await _chatService.sendMediaMessage(
          receiverId: _currentGroup!.id,
          mediaFile: File(file.path),
          groupId: _currentGroup!.id,
          isGroupMessage: true,
        );

        // Refresh messages to show the new media message
        _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending video: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _handleMessageTap(MessageModel message) {
    if (message.isImageMessage || message.isVideoMessage) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MediaViewer(message: message)),
      );
    }
  }
}
