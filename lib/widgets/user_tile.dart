import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../constants.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final VoidCallback? onTap;
  final int unreadCount;

  const UserTile({
    Key? key,
    required this.user,
    this.lastMessage,
    this.lastMessageTime,
    this.onTap,
    this.unreadCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.photoUrl)
                    : null,
            child:
                user.photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 24)
                    : null,
          ),
          // Online status indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color:
                    user.isOnline
                        ? AppColors.onlineGreen
                        : AppColors.offlineGray,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(user.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastMessage != null)
            Text(lastMessage!, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            user.lastSeenText,
            style: TextStyle(
              fontSize: 12,
              color: user.isOnline ? AppColors.onlineGreen : Colors.grey,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lastMessageTime != null)
            Text(
              TimeOfDay.fromDateTime(lastMessageTime!).format(context),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
