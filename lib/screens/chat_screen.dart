import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../constants.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/media_picker_widget.dart';
import '../widgets/media_viewer.dart';
import '../widgets/typing_indicator.dart';
import '../screens/call_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CallService _callService = CallService();
  bool _showEmojiPicker = false;
  bool _showMediaPicker = false;
  bool _isLoading = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final UserModel otherUser =
          ModalRoute.of(context)!.settings.arguments as UserModel;
      ChatService().markMessagesAsRead(otherUser.uid);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text, String receiverId) {
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      ChatService().setTypingStatus(receiverId, true);
    }

    // Cancel previous timer
    _typingTimer?.cancel();

    // Set new timer to stop typing indicator after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        setState(() {
          _isTyping = false;
        });
        ChatService().setTypingStatus(receiverId, false);
      }
    });

    // If text becomes empty, immediately stop typing
    if (text.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });
      ChatService().setTypingStatus(receiverId, false);
      _typingTimer?.cancel();
    }
  }

  void _handleMediaMessageTap(MessageModel message) {
    if (message.isImageMessage || message.isVideoMessage) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MediaViewer(message: message)),
      );
    }
  }

  void _openMediaPicker(UserModel otherUser) {
    setState(() {
      _showEmojiPicker = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MediaPickerWidget(
            onMediaSelected: (file, fileType) async {
              Navigator.pop(context);
              await _sendMediaMessage(otherUser, file, fileType);
            },
            onCancel: () => Navigator.pop(context),
          ),
    );
  }

  Future<void> _sendMediaMessage(
    UserModel otherUser,
    File file,
    String fileType,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ChatService().sendMediaMessage(
        receiverId: otherUser.uid,
        mediaFile: file,
        caption: '', // Could add caption input later
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startVoiceCall(UserModel otherUser) async {
    try {
      // Initialize call service if not already done
      await _callService.initialize();

      // Request permissions
      final hasPermissions = await _callService.requestPermissions(
        isVideoCall: false,
      );
      if (!hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required for voice calls',
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      final call = await _callService.startCall(
        receiver: otherUser,
        callType: CallType.voice,
      );

      if (call != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallScreen(call: call)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start voice call: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _startVideoCall(UserModel otherUser) async {
    try {
      // Initialize call service if not already done
      await _callService.initialize();

      // Request permissions
      final hasPermissions = await _callService.requestPermissions(
        isVideoCall: true,
      );
      if (!hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Camera and microphone permissions are required for video calls',
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      final call = await _callService.startCall(
        receiver: otherUser,
        callType: CallType.video,
      );

      if (call != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallScreen(call: call)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel otherUser =
        ModalRoute.of(context)!.settings.arguments as UserModel;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
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
                padding: const EdgeInsets.only(
                  top: 40,
                  left: 16,
                  right: 16,
                  bottom: 16,
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
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.darkText,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppColors.lightGray,
                      backgroundImage:
                          otherUser.photoUrl.isNotEmpty
                              ? NetworkImage(otherUser.photoUrl)
                              : null,
                      child:
                          otherUser.photoUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        otherUser.name,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Voice call button
                    IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.primaryBlue,
                      ),
                      onPressed: () => _startVoiceCall(otherUser),
                    ),
                    // Video call button
                    IconButton(
                      icon: const Icon(
                        Icons.videocam,
                        color: AppColors.primaryBlue,
                      ),
                      onPressed: () => _startVideoCall(otherUser),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: ChatService().getMessages(otherUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var messages = snapshot.data ?? [];
                    messages.sort(
                      (a, b) => b.timestamp.compareTo(a.timestamp),
                    ); // Newest first for reverse ListView

                    return ListView.builder(
                      reverse: true, // Show latest messages at bottom
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUid;
                        return EnhancedMessageBubble(
                          message: msg,
                          isMe: isMe,
                          onTap: () {
                            // Handle message tap (e.g., for media viewing)
                            if (msg.isMediaMessage) {
                              _handleMediaMessageTap(msg);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              // Typing Indicator
              StreamBuilder<bool>(
                stream: ChatService().getTypingStatus(otherUser.uid),
                builder: (context, snapshot) {
                  final isOtherUserTyping = snapshot.data ?? false;
                  return TypingIndicator(
                    isVisible: isOtherUserTyping,
                    userName: otherUser.name,
                  );
                },
              ),
              // Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () => _openMediaPicker(otherUser),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.emoji_emotions,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onChanged: (text) {
                              _onTextChanged(text, otherUser.uid);
                            },
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() {
                                  _showEmojiPicker = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () async {
                              final text = _controller.text.trim();
                              if (text.isNotEmpty) {
                                try {
                                  // Stop typing indicator
                                  if (_isTyping) {
                                    setState(() {
                                      _isTyping = false;
                                    });
                                    ChatService().setTypingStatus(
                                      otherUser.uid,
                                      false,
                                    );
                                    _typingTimer?.cancel();
                                  }

                                  await ChatService().sendMessage(
                                    receiverId: otherUser.uid,
                                    text: text,
                                  );
                                  _controller.clear();
                                } catch (e) {
                                  print('Send message error: $e');
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Offstage(
                offstage: !_showEmojiPicker,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _controller.text += emoji.emoji;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                    config: Config(
                      columns: 7,
                      emojiSizeMax: 32,
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      initCategory: Category.RECENT,
                      bgColor: AppColors.lightGray,
                      indicatorColor: AppColors.primaryBlue,
                      iconColor: Colors.grey,
                      iconColorSelected: AppColors.primaryBlue,
                      backspaceColor: AppColors.primaryBlue,
                      skinToneDialogBgColor: Colors.white,
                      skinToneIndicatorColor: Colors.grey,
                      enableSkinTones: true,
                      recentTabBehavior: RecentTabBehavior.RECENT,
                      recentsLimit: 28,
                      noRecents: const Text('No Recents'),
                      loadingIndicator: const SizedBox.shrink(),
                      tabIndicatorAnimDuration: kTabScrollDuration,
                      categoryIcons: const CategoryIcons(),
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
