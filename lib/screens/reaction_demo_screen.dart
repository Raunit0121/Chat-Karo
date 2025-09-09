import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../widgets/reaction_picker.dart';
import '../constants.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ReactionDemoScreen extends StatefulWidget {
  const ReactionDemoScreen({Key? key}) : super(key: key);

  @override
  State<ReactionDemoScreen> createState() => _ReactionDemoScreenState();
}

class _ReactionDemoScreenState extends State<ReactionDemoScreen> {
  final List<MessageModel> _demoMessages = [];
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _createDemoMessages();
  }

  void _createDemoMessages() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    // Create demo messages with reactions
    _demoMessages.addAll([
      MessageModel(
        id: 'demo1',
        senderId: currentUser.uid,
        receiverId: 'other_user',
        text: 'Hello! How are you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        reactions: [
          MessageReaction(
            userId: 'other_user',
            emoji: '❤️',
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
          MessageReaction(
            userId: 'demo_user',
            emoji: '😊',
            timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
        ],
      ),
      MessageModel(
        id: 'demo2',
        senderId: 'other_user',
        receiverId: currentUser.uid,
        text: 'I\'m doing great! Thanks for asking.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        reactions: [
          MessageReaction(
            userId: currentUser.uid,
            emoji: '👍',
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ],
      ),
      MessageModel(
        id: 'demo3',
        senderId: currentUser.uid,
        receiverId: 'other_user',
        text: 'That\'s awesome! 😄',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaction Demo'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demoMessages.length,
        itemBuilder: (context, index) {
          final message = _demoMessages[index];
          final isMe = message.senderId == AuthService().currentUser?.uid;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentBlue,
                    child: Text(
                      'U',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.accentBlue : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.darkText,
                            fontSize: 16,
                          ),
                        ),
                        if (message.hasReactions()) ...[
                          const SizedBox(height: 8),
                          _buildReactionsDisplay(message),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '12:34',
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.done_all,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      'Me',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReactionPicker(),
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.emoji_emotions, color: Colors.white),
      ),
    );
  }

  Widget _buildReactionsDisplay(MessageModel message) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final uniqueEmojis = message.uniqueEmojis;
    if (uniqueEmojis.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          uniqueEmojis.map((emoji) {
            final count = message.getEmojiCount(emoji);
            final isSelected =
                message.getUserReaction(currentUser.uid) == emoji;

            return ReactionBubble(
              emoji: emoji,
              count: count,
              isSelected: isSelected,
              onTap: () => _showReactionDetail(message, emoji),
            );
          }).toList(),
    );
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ReactionPicker(
              onReactionSelected: (emoji) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected reaction: $emoji')),
                );
                Navigator.pop(context);
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _showReactionDetail(MessageModel message, String emoji) {
    final reactions = message.getReactionsForEmoji(emoji);
    if (reactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ReactionDetailSheet(
              reactionsByEmoji: {
                emoji: reactions.map((r) => r.toMap()).toList(),
              },
              onReactionSelected: (selectedEmoji) {
                Navigator.pop(context);
                _showReactionPicker();
              },
            ),
          ),
    );
  }
}
