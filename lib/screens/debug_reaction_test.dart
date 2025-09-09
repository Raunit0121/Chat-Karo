import 'package:flutter/material.dart';
import '../constants.dart';

class DebugReactionTest extends StatefulWidget {
  const DebugReactionTest({Key? key}) : super(key: key);

  @override
  State<DebugReactionTest> createState() => _DebugReactionTestState();
}

class _DebugReactionTestState extends State<DebugReactionTest> {
  String _debugInfo = 'No action yet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Reaction Test'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Debug info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Info:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_debugInfo),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test message with long press
            GestureDetector(
              onLongPress: () {
                setState(() {
                  _debugInfo = 'Long press detected! Showing menu...';
                });
                _showTestMenu(context);
              },
              onTap: () {
                setState(() {
                  _debugInfo = 'Tap detected';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Long press this message to test',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test reaction picker directly
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _debugInfo = 'Testing reaction picker directly...';
                });
                _showReactionPicker(context);
              },
              child: const Text('Test Reaction Picker Directly'),
            ),

            const SizedBox(height: 20),

            // Instructions
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Long press the blue message above\n'
              '2. Check if menu appears with "React to Message"\n'
              '3. Or click the button to test reaction picker directly\n'
              '4. Watch the debug info for status updates',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Message Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  title: const Text('Edit Message'),
                  onTap: () {
                    setState(() {
                      _debugInfo = 'Edit Message selected';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.errorRed),
                  title: const Text('Delete Message'),
                  onTap: () {
                    setState(() {
                      _debugInfo = 'Delete Message selected';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.emoji_emotions,
                    color: AppColors.accentBlue,
                  ),
                  title: const Text('React to Message'),
                  onTap: () {
                    setState(() {
                      _debugInfo = 'React to Message selected';
                    });
                    Navigator.pop(context);
                    _showReactionPicker(context);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _debugInfo = 'Menu cancelled';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    setState(() {
      _debugInfo = 'Showing reaction picker...';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'React to message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                // Reactions grid
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        ['❤️', '😊', '😂', '😮', '😢', '😡', '👍', '👎'].map((
                          emoji,
                        ) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _debugInfo = 'Reaction selected: $emoji';
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _debugInfo = 'Reaction picker cancelled';
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
