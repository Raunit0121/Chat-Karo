import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../constants.dart';
import 'media_service.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MediaService _mediaService = MediaService();
  final NotificationService _notificationService = NotificationService();

  // Get all users except the current user
  Stream<List<UserModel>> getUsers() {
    final currentUid = _auth.currentUser?.uid;
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Send a text message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    String? groupId,
    bool isGroupMessage = false,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // For group messages, get all group members as participants
    List<String> participants = [currentUid, receiverId];
    if (isGroupMessage && groupId != null) {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data()!;
        participants = List<String>.from(groupData['members'] ?? []);
      }
    }

    final messageRef = _firestore.collection('chats').doc();
    final message = MessageModel(
      id: messageRef.id,
      senderId: currentUid,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      participants: participants,
      readBy: [currentUid],
      messageType: MessageType.text,
      status: MessageStatus.sent,
    );

    final messageData = message.toMap();
    if (isGroupMessage && groupId != null) {
      // Store group information as top-level fields for consistency
      messageData['groupId'] = groupId;
      messageData['isGroupMessage'] = true;
    }

    await messageRef.set(messageData);

    // Update group's last activity if it's a group message
    if (isGroupMessage && groupId != null) {
      await _firestore.collection('groups').doc(groupId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    }

    await _sendNotificationToUser(receiverId, text, MessageType.text);
  }

  // Send a media message
  Future<void> sendMediaMessage({
    required String receiverId,
    required File mediaFile,
    String? caption,
    String? groupId,
    bool isGroupMessage = false,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Determine file type
      final fileType = _mediaService.getFileType(mediaFile.path);

      // Upload media to Cloudinary
      Map<String, dynamic>? uploadResult;
      switch (fileType) {
        case MessageType.image:
          uploadResult = await _mediaService.uploadImage(mediaFile);
          break;
        case MessageType.video:
          uploadResult = await _mediaService.uploadVideo(mediaFile);
          break;
        case MessageType.file:
          uploadResult = await _mediaService.uploadFile(mediaFile);
          break;
      }

      if (uploadResult == null) {
        throw Exception('Failed to upload media to Cloudinary');
      }

      // For group messages, get all group members as participants
      List<String> participants = [currentUid, receiverId];
      if (isGroupMessage && groupId != null) {
        final groupDoc =
            await _firestore.collection('groups').doc(groupId).get();
        if (groupDoc.exists) {
          final groupData = groupDoc.data()!;
          participants = List<String>.from(groupData['members'] ?? []);
        }
      }

      // Create message
      final messageRef = _firestore.collection('chats').doc();
      final message = MessageModel(
        id: messageRef.id,
        senderId: currentUid,
        receiverId: receiverId,
        text: caption ?? '',
        timestamp: DateTime.now(),
        participants: participants,
        readBy: [currentUid],
        messageType: fileType,
        mediaUrl: uploadResult['url'],
        fileName:
            uploadResult['original_filename'] ?? mediaFile.path.split('/').last,
        fileSize: uploadResult['bytes'],
        thumbnailUrl: uploadResult['thumbnail_url'],
        status: MessageStatus.sent,
        metadata: uploadResult,
      );

      final messageData = message.toMap();
      if (isGroupMessage && groupId != null) {
        // Store group information as top-level fields for consistency
        messageData['groupId'] = groupId;
        messageData['isGroupMessage'] = true;
      }

      await messageRef.set(messageData);

      // Update group's last activity if it's a group message
      if (isGroupMessage && groupId != null) {
        await _firestore.collection('groups').doc(groupId).update({
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }
      await _sendNotificationToUser(receiverId, message.displayText, fileType);
    } catch (e) {
      print('Error sending media message: $e');
      throw e.toString();
    }
  }

  // Mark all messages from otherUserId as read by the current user
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;
    final query =
        await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUid)
            .where('senderId', isEqualTo: otherUserId)
            .where('readBy', whereNotIn: [currentUid])
            .get();
    for (final doc in query.docs) {
      await doc.reference.update({
        'readBy': FieldValue.arrayUnion([currentUid]),
      });
    }
  }

  // Stream messages between two users
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final allMsgs =
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.data()))
                  .toList();
          print('Fetched ${allMsgs.length} messages for user $currentUid');
          allMsgs.forEach(
            (msg) => print(
              'Fetched message: senderId=${msg.senderId}, receiverId=${msg.receiverId}, text=${msg.text}, participants=${msg.participants}',
            ),
          );
          final filtered =
              allMsgs
                  .where(
                    (msg) =>
                        ((msg.senderId == currentUid &&
                                msg.receiverId == otherUserId) ||
                            (msg.senderId == otherUserId &&
                                msg.receiverId == currentUid)) &&
                        !msg.isDeletedForUser(currentUid),
                  )
                  .toList();
          print(
            'Filtered to ${filtered.length} messages between $currentUid and $otherUserId',
          );
          return filtered;
        });
  }

  // Typing indicator methods
  Future<void> setTypingStatus(String receiverId, bool isTyping) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    final chatId = _getChatId(currentUid, receiverId);

    if (isTyping) {
      await _firestore.collection('typing_indicators').doc(chatId).set({
        'typingUsers': {currentUid: DateTime.now().millisecondsSinceEpoch},
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } else {
      await _firestore.collection('typing_indicators').doc(chatId).update({
        'typingUsers.$currentUid': FieldValue.delete(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Stream<bool> getTypingStatus(String otherUserId) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return Stream.value(false);

    final chatId = _getChatId(currentUid, otherUserId);

    return _firestore.collection('typing_indicators').doc(chatId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final typingUsers = data['typingUsers'] as Map<String, dynamic>?;
      if (typingUsers == null) return false;

      // Check if other user is typing and the timestamp is recent (within 3 seconds)
      final otherUserTyping = typingUsers[otherUserId];
      if (otherUserTyping == null) return false;

      final timestamp = otherUserTyping as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isRecent = (now - timestamp) < 3000; // 3 seconds

      return isRecent;
    });
  }

  String _getChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Delete message functionality
  Future<void> deleteMessageForMe(String messageId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      await _firestore.collection('chats').doc(messageId).update({
        'deletedFor': FieldValue.arrayUnion([currentUid]),
      });
    } catch (e) {
      print('Error deleting message for me: $e');
      throw e.toString();
    }
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Get the message to check if current user is the sender
      final messageDoc =
          await _firestore.collection('chats').doc(messageId).get();
      if (!messageDoc.exists) {
        throw 'Message not found';
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final senderId = messageData['senderId'] as String;

      // Only allow sender to delete for everyone
      if (senderId != currentUid) {
        throw 'Only the sender can delete messages for everyone';
      }

      // Check if message is older than 24 hours
      final timestamp = (messageData['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inHours > 24) {
        throw 'Messages older than 24 hours cannot be deleted for everyone';
      }

      await _firestore.collection('chats').doc(messageId).update({
        'deletedForEveryone': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting message for everyone: $e');
      throw e.toString();
    }
  }

  // Edit message functionality
  Future<void> editMessage(String messageId, String newText) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Get the message to check if current user is the sender
      final messageDoc =
          await _firestore.collection('chats').doc(messageId).get();
      if (!messageDoc.exists) {
        throw 'Message not found';
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final senderId = messageData['senderId'] as String;

      // Only allow sender to edit messages
      if (senderId != currentUid) {
        throw 'Only the sender can edit messages';
      }

      // Check if message is older than 24 hours
      final timestamp = (messageData['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inHours > 24) {
        throw 'Messages older than 24 hours cannot be edited';
      }

      // Check if message is already deleted
      final deletedForEveryone = messageData['deletedForEveryone'] ?? false;
      if (deletedForEveryone) {
        throw 'Deleted messages cannot be edited';
      }

      // Store original text in edit history if this is the first edit
      Map<String, dynamic> editHistory = {};
      if (messageData['editHistory'] != null) {
        editHistory = Map<String, dynamic>.from(messageData['editHistory']);
      } else {
        // First edit - store original text
        editHistory['original'] = {
          'text': messageData['text'],
          'timestamp': messageData['timestamp'],
        };
      }

      // Add current edit to history
      final editCount = editHistory.length;
      editHistory['edit_$editCount'] = {
        'text': newText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chats').doc(messageId).update({
        'text': newText,
        'isEdited': true,
        'lastEditedAt': FieldValue.serverTimestamp(),
        'editHistory': editHistory,
      });
    } catch (e) {
      print('Error editing message: $e');
      throw e.toString();
    }
  }

  // Get group messages
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    print('DEBUG: Getting group messages for groupId: $groupId');

    // Use simple query that works without complex indexes
    return _firestore.collection('chats').where('groupId', isEqualTo: groupId).snapshots().map((
      snapshot,
    ) {
      print(
        'DEBUG: Group messages query returned ${snapshot.docs.length} documents',
      );
      final allMessages =
          snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();

      print('DEBUG: All messages from query:');
      for (var msg in allMessages) {
        // Check both top-level and metadata for backward compatibility
        final topLevelGroupId = msg.metadata?['groupId'] ?? 'none';
        print(
          '  Message: id=${msg.id}, senderId=${msg.senderId}, receiverId=${msg.receiverId}, text=${msg.text}, groupId=$topLevelGroupId',
        );
      }

      final messages =
          allMessages.where((message) {
            final currentUid = _auth.currentUser?.uid;
            if (currentUid == null) return false;

            // Since we're already querying by groupId, all messages should be for this group
            // Just check if the message is not deleted for the current user
            final isNotDeleted = !message.isDeletedForUser(currentUid);

            print(
              'DEBUG: Filtering message ${message.id}: isNotDeleted=$isNotDeleted',
            );

            return isNotDeleted;
          }).toList();

      // Sort in memory if needed (for fallback query)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('DEBUG: Processed ${messages.length} group messages');
      return messages;
    });
  }

  // Get group messages (Future version for one-time fetch)
  Future<List<MessageModel>> getGroupMessagesOnce(String groupId) async {
    print('DEBUG: Getting group messages once for groupId: $groupId');

    try {
      final snapshot =
          await _firestore
              .collection('chats')
              .where('groupId', isEqualTo: groupId)
              .get();

      print(
        'DEBUG: Group messages query returned ${snapshot.docs.length} documents',
      );

      final allMessages =
          snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();

      final messages =
          allMessages.where((message) {
            final currentUid = _auth.currentUser?.uid;
            if (currentUid == null) return false;

            // Since we're already querying by groupId, all messages should be for this group
            // Just check if the message is not deleted for the current user
            final isNotDeleted = !message.isDeletedForUser(currentUid);

            print(
              'DEBUG: Filtering message ${message.id}: isNotDeleted=$isNotDeleted',
            );

            return isNotDeleted;
          }).toList();

      // Sort by timestamp (oldest first for WhatsApp-style behavior)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('DEBUG: Processed ${messages.length} group messages');
      return messages;
    } catch (e) {
      print('ERROR: Failed to get group messages: $e');
      return [];
    }
  }

  // Get the last message between current user and another user
  Stream<MessageModel?> getLastMessage(String otherUserId) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .where(
                (msg) =>
                    (msg.senderId == currentUid &&
                        msg.receiverId == otherUserId) ||
                    (msg.senderId == otherUserId &&
                        msg.receiverId == currentUid),
              );
          return docs.isNotEmpty ? docs.first : null;
        });
  }

  // Stream the count of unread messages from otherUserId to the current user
  Stream<int> getUnreadCount(String otherUserId) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return Stream<int>.value(0);
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUid)
        .where('readBy', whereNotIn: [currentUid])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Update message delivery status
  Future<void> updateMessageStatus(String messageId, String status) async {
    try {
      await _firestore.collection('chats').doc(messageId).update({
        'status': status,
        if (status == MessageStatus.delivered)
          'deliveredAt': FieldValue.serverTimestamp(),
        if (status == MessageStatus.read)
          'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating message status: $e');
    }
  }

  // Send notification to user
  Future<void> _sendNotificationToUser(
    String receiverId,
    String message,
    String messageType,
  ) async {
    try {
      // Get receiver's FCM token
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      final receiverData = UserModel.fromMap(receiverDoc.data()!);
      if (receiverData.fcmToken == null) return;

      // Get sender's name
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      final senderDoc =
          await _firestore.collection('users').doc(currentUid).get();
      if (!senderDoc.exists) return;

      final senderData = UserModel.fromMap(senderDoc.data()!);

      // Send notification
      await _notificationService.sendNotificationToUser(
        userToken: receiverData.fcmToken!,
        title: senderData.name,
        body:
            messageType == MessageType.text
                ? message
                : _getMediaNotificationText(messageType),
        data: {
          'senderId': currentUid,
          'senderName': senderData.name,
          'messageType': messageType,
          'chatId': _getChatId(currentUid, receiverId),
        },
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Get media notification text
  String _getMediaNotificationText(String messageType) {
    switch (messageType) {
      case MessageType.image:
        return '📷 Sent a photo';
      case MessageType.video:
        return '🎥 Sent a video';
      case MessageType.file:
        return '📄 Sent a file';
      case MessageType.audio:
        return '🎵 Sent an audio';
      default:
        return 'Sent a message';
    }
  }

  // Mark messages as delivered when user comes online
  Future<void> markMessagesAsDelivered(String otherUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final undeliveredMessages =
          await _firestore
              .collection('chats')
              .where('receiverId', isEqualTo: currentUid)
              .where('senderId', isEqualTo: otherUserId)
              .where('status', isEqualTo: MessageStatus.sent)
              .get();

      final batch = _firestore.batch();
      for (final doc in undeliveredMessages.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.delivered,
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as delivered: $e');
    }
  }

  // Reaction methods
  Future<void> addReaction(String messageId, String emoji) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Get current message
      final messageDoc = await _firestore.collection('chats').doc(messageId).get();
      if (!messageDoc.exists) {
        throw 'Message not found';
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> reactions = [];
      
      if (messageData['reactions'] != null) {
        reactions = List<Map<String, dynamic>>.from(messageData['reactions']);
      }

      // Remove existing reaction from this user if any
      reactions.removeWhere((reaction) => reaction['userId'] == currentUid);

      // Add new reaction
      reactions.add({
        'userId': currentUid,
        'emoji': emoji,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(messageId).update({
        'reactions': reactions,
      });

      // Send notification for reaction
      final senderId = messageData['senderId'] as String;
      if (senderId != currentUid) {
        await _sendReactionNotification(senderId, emoji);
      }
    } catch (e) {
      print('Error adding reaction: $e');
      throw e.toString();
    }
  }

  Future<void> removeReaction(String messageId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final messageDoc = await _firestore.collection('chats').doc(messageId).get();
      if (!messageDoc.exists) {
        throw 'Message not found';
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> reactions = [];
      
      if (messageData['reactions'] != null) {
        reactions = List<Map<String, dynamic>>.from(messageData['reactions']);
      }

      // Remove reaction from this user
      reactions.removeWhere((reaction) => reaction['userId'] == currentUid);

      await _firestore.collection('chats').doc(messageId).update({
        'reactions': reactions,
      });
    } catch (e) {
      print('Error removing reaction: $e');
      throw e.toString();
    }
  }

  Future<void> _sendReactionNotification(String receiverId, String emoji) async {
    try {
      // Get receiver's FCM token
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      if (!receiverDoc.exists) return;

      final receiverData = UserModel.fromMap(receiverDoc.data()!);
      if (receiverData.fcmToken == null) return;

      // Get sender's name
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return;

      final senderDoc = await _firestore.collection('users').doc(currentUid).get();
      if (!senderDoc.exists) return;

      final senderData = UserModel.fromMap(senderDoc.data()!);

      // Send notification
      await _notificationService.sendNotificationToUser(
        userToken: receiverData.fcmToken!,
        title: senderData.name,
        body: 'Reacted with $emoji',
        data: {
          'senderId': currentUid,
          'senderName': senderData.name,
          'messageType': 'reaction',
          'emoji': emoji,
        },
      );
    } catch (e) {
      print('Error sending reaction notification: $e');
    }
  }
}
