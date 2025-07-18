import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final List<String>? participants;
  final List<String>? readBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.participants,
    this.readBy,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime ts;
    final rawTs = map['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is DateTime) {
      ts = rawTs;
    } else if (rawTs is String) {
      ts = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }
    final msg = MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: ts,
      participants: (map['participants'] as List?)?.map((e) => e.toString()).toList(),
      readBy: (map['readBy'] as List?)?.map((e) => e.toString()).toList(),
    );
    print('Parsed message: id=${msg.id}, senderId=${msg.senderId}, receiverId=${msg.receiverId}, text=${msg.text}, timestamp=${msg.timestamp}, participants=${msg.participants}, readBy=${msg.readBy}');
    return msg;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'participants': participants ?? [senderId, receiverId],
      'readBy': readBy ?? [senderId],
    };
  }
} 