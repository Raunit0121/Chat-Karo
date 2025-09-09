import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../constants.dart';
import '../services/auth_service.dart';

class SimpleReactionTest extends StatefulWidget {
  const SimpleReactionTest({Key? key}) : super(key: key);

  @override
  State<SimpleReactionTest> createState() => _SimpleReactionTestState();
}

class _SimpleReactionTestState extends State<SimpleReactionTest> {
  final List<MessageModel> _testMessages = [];
  final UserModel _testUser = UserModel(
    uid: 'test_user',
    name: 'Test User',
    email: 'test@example.com',
    photoUrl: '',
  );

  @override
  void initState() {
    super.initState();
    _createTestMessages();
  }

  void _createTestMessages() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    _testMessages.addAll([
      MessageModel(
        id: 'test1',
        senderId: currentUser.uid,
        receiverId: 'other_user',
        text: 'Hello! This is a test message for reactions.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      MessageModel(
        id: 'test2',
        senderId: 'other_user',
        receiverId: currentUser.uid,
        text: 'Hi! This is a reply message.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      MessageModel(
        id: 'test3',
        senderId: currentUser.uid,
        receiverId: 'other_user',
        text: 'This message has reactions!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        reactions: [
          MessageReaction(
            userId: 'other_user',
            emoji: '❤️',
            timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Reaction Test'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Long press on any message below\n'
                  '2. You should see "React to Message" option\n'
                  '3. Select it to open the emoji picker\n'
                  '4. Choose an emoji to add a reaction',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          
          // Test messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testMessages.length,
              itemBuilder: (context, index) {
                final message = _testMessages[index];
                final currentUser = AuthService().currentUser;
                final isMe = currentUser != null && message.senderId == currentUser!.uid;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: EnhancedMessageBubble(
                    message: message,
                    isMe: isMe,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tapped message: ${message.text}')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Debug info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current User: ${AuthService().currentUser?.uid ?? 'Not logged in'}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Messages: ${_testMessages.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Messages with reactions: ${_testMessages.where((m) => m.hasReactions()).length}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
