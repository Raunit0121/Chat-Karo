import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final UserModel otherUser = ModalRoute.of(context)!.settings.arguments as UserModel;
      ChatService().markMessagesAsRead(otherUser.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserModel otherUser = ModalRoute.of(context)!.settings.arguments as UserModel;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final cloudinaryService = CloudinaryService();
    
    // Get optimized profile picture URL
    String? optimizedImageUrl;
    if (otherUser.photoUrl.isNotEmpty) {
      final publicId = cloudinaryService.extractPublicId(otherUser.photoUrl);
      if (publicId != null) {
        optimizedImageUrl = cloudinaryService.getProfilePictureUrl(publicId, size: 40);
      } else {
        optimizedImageUrl = otherUser.photoUrl;
      }
    }
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
                padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.teal,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: optimizedImageUrl != null
                            ? Image.network(
                                optimizedImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.teal.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.account_circle,
                                      size: 28,
                                      color: Colors.teal,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.teal.withOpacity(0.1),
                                child: const Icon(
                                  Icons.account_circle,
                                  size: 28,
                                  color: Colors.teal,
                                ),
                              ),
                      ),
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
                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUid;
                        return MessageBubble(
                          text: msg.text,
                          isMe: isMe,
                          time: msg.timestamp,
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.emoji_emotions, color: AppColors.primaryBlue),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
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