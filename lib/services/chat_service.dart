import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all users except the current user
  Stream<List<UserModel>> getUsers() {
    final currentUid = _auth.currentUser?.uid;
    return _firestore.collection('users')
      .where('uid', isNotEqualTo: currentUid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;
    final messageRef = _firestore.collection('chats').doc();
    final message = MessageModel(
      id: messageRef.id,
      senderId: currentUid,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      participants: [currentUid, receiverId],
      readBy: [currentUid],
    );
    await messageRef.set(message.toMap());
  }

  // Mark all messages from otherUserId as read by the current user
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;
    final query = await _firestore.collection('chats')
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
    return _firestore.collection('chats')
      .where('participants', arrayContains: currentUid)
      .snapshots()
      .map((snapshot) {
        final allMsgs = snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
        print('Fetched ${allMsgs.length} messages for user $currentUid');
        allMsgs.forEach((msg) => print('Fetched message: senderId=${msg.senderId}, receiverId=${msg.receiverId}, text=${msg.text}, participants=${msg.participants}'));
        final filtered = allMsgs.where((msg) =>
          (msg.senderId == currentUid && msg.receiverId == otherUserId) ||
          (msg.senderId == otherUserId && msg.receiverId == currentUid)
        ).toList();
        print('Filtered to ${filtered.length} messages between $currentUid and $otherUserId');
        return filtered;
      });
  }

  // Get the last message between current user and another user
  Stream<MessageModel?> getLastMessage(String otherUserId) {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      return const Stream.empty();
    }
    return _firestore.collection('chats')
      .where('participants', arrayContains: currentUid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data()))
          .where((msg) =>
            (msg.senderId == currentUid && msg.receiverId == otherUserId) ||
            (msg.senderId == otherUserId && msg.receiverId == currentUid)
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
    return _firestore.collection('chats')
      .where('participants', arrayContains: currentUid)
      .where('senderId', isEqualTo: otherUserId)
      .where('receiverId', isEqualTo: currentUid)
      .where('readBy', whereNotIn: [currentUid])
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
  }
} 