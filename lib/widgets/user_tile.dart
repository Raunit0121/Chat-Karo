import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/cloudinary_service.dart';

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
    final cloudinaryService = CloudinaryService();
    String? optimizedImageUrl;
    
    if (user.photoUrl.isNotEmpty) {
      final publicId = cloudinaryService.extractPublicId(user.photoUrl);
      if (publicId != null) {
        optimizedImageUrl = cloudinaryService.getThumbnailUrl(publicId, size: 50);
      } else {
        optimizedImageUrl = user.photoUrl;
      }
    }
    
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
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
                        size: 36,
                        color: Colors.teal,
                      ),
                    );
                  },
                )
              : Container(
                  color: Colors.teal.withOpacity(0.1),
                  child: const Icon(
                    Icons.account_circle,
                    size: 36,
                    color: Colors.teal,
                  ),
                ),
        ),
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