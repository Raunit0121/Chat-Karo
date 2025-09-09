import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class MessageDeleteDialog extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;

  const MessageDeleteDialog({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool canDeleteForEveryone = message.canDeleteForEveryone(
      currentUserId,
    );
    final bool isSender = message.senderId == currentUserId;

    return AlertDialog(
      title: const Text(
        'Delete Message',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to delete this message?',
            style: TextStyle(color: AppColors.darkText),
          ),
          const SizedBox(height: 16),
          if (isSender && canDeleteForEveryone) ...[
            const Text(
              'Choose delete option:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Delete for me: Only removes the message from your chat',
              style: TextStyle(fontSize: 12, color: AppColors.offlineGray),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Delete for everyone: Removes the message for all participants',
              style: TextStyle(fontSize: 12, color: AppColors.offlineGray),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Messages can only be deleted for everyone within 24 hours',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.offlineGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            const Text(
              'This message will be deleted only from your chat.',
              style: TextStyle(fontSize: 12, color: AppColors.offlineGray),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.offlineGray),
          ),
        ),
        TextButton(
          onPressed: () => _deleteForMe(context),
          child: const Text(
            'Delete for me',
            style: TextStyle(color: AppColors.primaryBlue),
          ),
        ),
        if (isSender && canDeleteForEveryone)
          TextButton(
            onPressed: () => _deleteForEveryone(context),
            child: const Text(
              'Delete for everyone',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
      ],
    );
  }

  void _deleteForMe(BuildContext context) async {
    try {
      await ChatService().deleteMessageForMe(message.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _deleteForEveryone(BuildContext context) async {
    try {
      await ChatService().deleteMessageForEveryone(message.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted for everyone'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
