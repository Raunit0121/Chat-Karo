import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../constants.dart';

class ReactionTestScreen extends StatefulWidget {
  const ReactionTestScreen({Key? key}) : super(key: key);

  @override
  State<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends State<ReactionTestScreen> {
  final ChatService _chatService = ChatService();
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaction Test'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading) const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAddReaction,
              child: const Text('Test Add Reaction'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRemoveReaction,
              child: const Text('Test Remove Reaction'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateMessage,
              child: const Text('Create Test Message'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. First create a test message\n'
              '2. Then try adding a reaction\n'
              '3. Check Firestore console for results\n'
              '4. Try removing the reaction',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateMessage() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test message...';
    });

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        setState(() {
          _status = 'Error: User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Create a test message
      await _chatService.sendMessage(
        receiverId: 'test_receiver',
        text: 'This is a test message for reactions',
      );

      setState(() {
        _status = 'Test message created successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error creating message: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAddReaction() async {
    setState(() {
      _isLoading = true;
      _status = 'Adding reaction...';
    });

    try {
      // You'll need to replace this with an actual message ID from your database
      const testMessageId = 'test_message_id'; // Replace with real message ID

      await _chatService.addReaction(testMessageId, '❤️');

      setState(() {
        _status = 'Reaction added successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding reaction: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testRemoveReaction() async {
    setState(() {
      _isLoading = true;
      _status = 'Removing reaction...';
    });

    try {
      // You'll need to replace this with an actual message ID from your database
      const testMessageId = 'test_message_id'; // Replace with real message ID

      await _chatService.removeReaction(testMessageId);

      setState(() {
        _status = 'Reaction removed successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error removing reaction: $e';
        _isLoading = false;
      });
    }
  }
}
