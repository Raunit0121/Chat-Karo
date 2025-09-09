import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class MessageEditDialog extends StatefulWidget {
  final MessageModel message;

  const MessageEditDialog({
    super.key,
    required this.message,
  });

  @override
  State<MessageEditDialog> createState() => _MessageEditDialogState();
}

class _MessageEditDialogState extends State<MessageEditDialog> {
  late TextEditingController _textController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.message.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Edit Message',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textController,
            maxLines: null,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type your message...',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.message.isEdited) ...[
            const Text(
              'Edit History:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.message.editHistoryList.map((edit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${edit['text']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.offlineGray,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Note: Messages can only be edited within 24 hours',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.offlineGray,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.offlineGray),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _saveEdit() async {
    final newText = _textController.text.trim();
    
    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (newText == widget.message.text) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ChatService().editMessage(widget.message.id, newText);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message edited successfully'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
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
