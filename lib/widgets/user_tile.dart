import 'package:flutter/material.dart';
import '../models/user_model.dart';

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
      leading: CircleAvatar(
        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
        child: user.photoUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(user.name),
      subtitle: lastMessage != null ? Text(lastMessage!) : null,
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
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
} 