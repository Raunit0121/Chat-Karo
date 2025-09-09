import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'message_delete_dialog.dart';
import 'message_edit_dialog.dart';
import 'reaction_picker.dart';

class EnhancedMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onTap;
  final bool showSenderName;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.showSenderName = false,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.message.isVideoMessage && widget.message.mediaUrl != null) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.message.mediaUrl!),
    );
    _videoController!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if message is deleted for current user
    final currentUser = AuthService().currentUser;
    if (currentUser != null &&
        widget.message.isDeletedForUser(currentUser.uid)) {
      return _buildDeletedMessage();
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isMe ? 50 : 10,
          right: widget.isMe ? 10 : 50,
          top: 5,
          bottom: 5,
        ),
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe ? AppColors.accentBlue : AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender name for group messages
                if (widget.showSenderName && !widget.isMe) ...[
                  FutureBuilder<String>(
                    future: _getSenderName(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            snapshot.data!,
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],

                // Media content
                if (widget.message.isMediaMessage) _buildMediaContent(),

                // Text content
                if (widget.message.text.isNotEmpty) ...[
                  if (widget.message.isMediaMessage) const SizedBox(height: 8),
                  Text(
                    widget.message.editedDisplayText,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white : AppColors.darkText,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.message.isEdited) ...[
                    const SizedBox(height: 4),
                    Text(
                      'edited',
                      style: TextStyle(
                        color:
                            widget.isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.darkText.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],

                // Reactions
                if (widget.message.hasReactions()) ...[
                  const SizedBox(height: 8),
                  _buildReactionsDisplay(),
                ],

                const SizedBox(height: 4),

                // Timestamp and status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(widget.message.timestamp),
                      style: TextStyle(
                        color:
                            widget.isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.darkText.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (widget.isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.message.messageType) {
      case MessageType.image:
        return _buildImageContent();
      case MessageType.video:
        return _buildVideoContent();
      case MessageType.file:
        return _buildFileContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageContent() {
    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: CachedNetworkImage(
            imageUrl: widget.message.mediaUrl!,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
          child: Stack(
            children: [
              if (_videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else if (widget.message.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: widget.message.thumbnailUrl!,
                  fit: BoxFit.cover,
                  height: 150,
                  placeholder:
                      (context, url) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.videocam, size: 50),
                      ),
                )
              else
                Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.videocam, size: 50, color: Colors.grey),
                  ),
                ),

              // Play button overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file,
            color: AppColors.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.fileName ?? 'File',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.message.fileSize != null)
                  Text(
                    _formatFileSize(widget.message.fileSize!),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 16, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return const Icon(Icons.access_time, size: 16, color: Colors.white70);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildDeletedMessage() {
    return Container(
      margin: EdgeInsets.only(
        left: widget.isMe ? 50 : 10,
        right: widget.isMe ? 10 : 50,
        top: 5,
        bottom: 5,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.offlineGray.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                size: 16,
                color: AppColors.offlineGray.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                widget.message.deletedForEveryone
                    ? 'This message was deleted'
                    : 'You deleted this message',
                style: TextStyle(
                  color: AppColors.offlineGray.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    print('DEBUG: _showMessageOptions called');
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user in message options');
      return;
    }

    print('DEBUG: Showing message options for message: ${widget.message.id}');
    final canEdit = widget.message.canEdit(currentUser.uid);
    const canDelete = true; // Everyone can delete messages for themselves

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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                if (canEdit) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.edit,
                      color: AppColors.primaryBlue,
                    ),
                    title: const Text('Edit Message'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditDialog(context);
                    },
                  ),
                ],
                if (canDelete) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.delete,
                      color: AppColors.errorRed,
                    ),
                    title: const Text('Delete Message'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteDialog(context);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(
                    Icons.emoji_emotions,
                    color: AppColors.accentBlue,
                  ),
                  title: const Text('React to Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReactionPicker(context);
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.offlineGray),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MessageEditDialog(message: widget.message),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder:
          (context) => MessageDeleteDialog(
            message: widget.message,
            currentUserId: currentUser.uid,
          ),
    );
  }

  Future<String> _getSenderName() async {
    try {
      final chatService = ChatService();
      final user = await chatService.getUserById(widget.message.senderId);
      return user?.name ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  Widget _buildReactionsDisplay() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final uniqueEmojis = widget.message.uniqueEmojis;
    if (uniqueEmojis.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: uniqueEmojis.map((emoji) {
        final count = widget.message.getEmojiCount(emoji);
        final isSelected = widget.message.getUserReaction(currentUser.uid) == emoji;
        
        return ReactionBubble(
          emoji: emoji,
          count: count,
          isSelected: isSelected,
          onTap: () => _showReactionDetail(emoji),
        );
      }).toList(),
    );
  }

  void _showReactionPicker(BuildContext context) {
    print('DEBUG: _showReactionPicker called');
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user found');
      return;
    }

    print('DEBUG: Showing reaction picker for message: ${widget.message.id}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReactionPicker(
          onReactionSelected: (emoji) async {
            print('DEBUG: Reaction selected: $emoji');
            try {
              final chatService = ChatService();
              final userReaction = widget.message.getUserReaction(currentUser.uid);
              
              if (userReaction == emoji) {
                // Remove reaction if same emoji is selected
                print('DEBUG: Removing reaction');
                await chatService.removeReaction(widget.message.id);
              } else {
                // Add or change reaction
                print('DEBUG: Adding reaction: $emoji');
                await chatService.addReaction(widget.message.id, emoji);
              }
            } catch (e) {
              print('DEBUG: Error in reaction: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          onClose: () {
            print('DEBUG: Reaction picker closed');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showReactionDetail(String emoji) {
    final reactions = widget.message.getReactionsForEmoji(emoji);
    if (reactions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReactionDetailSheet(
          reactionsByEmoji: {emoji: reactions.map((r) => r.toMap()).toList()},
          onReactionSelected: (selectedEmoji) {
            Navigator.pop(context);
            _showReactionPicker(context);
          },
        ),
      ),
    );
  }
}
