import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime timestamp;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'emoji': emoji,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MessageReaction.fromMap(Map<String, dynamic> map) {
    return MessageReaction(
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageReaction && 
           other.userId == userId && 
           other.emoji == emoji;
  }

  @override
  int get hashCode => userId.hashCode ^ emoji.hashCode;
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final List<String>? participants;
  final List<String>? readBy;
  final String messageType;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final String status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final List<String>? deletedFor;
  final bool deletedForEveryone;
  final DateTime? deletedAt;
  final bool isEdited;
  final DateTime? lastEditedAt;
  final Map<String, dynamic>? editHistory;
  final List<MessageReaction>? reactions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.participants,
    this.readBy,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
    this.metadata,
    this.deletedFor,
    this.deletedForEveryone = false,
    this.deletedAt,
    this.isEdited = false,
    this.lastEditedAt,
    this.editHistory,
    this.reactions,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

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

    // Parse reactions
    List<MessageReaction>? reactions;
    if (map['reactions'] != null) {
      final reactionsList = map['reactions'] as List;
      reactions = reactionsList
          .map((reaction) => MessageReaction.fromMap(reaction))
          .toList();
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: ts,
      participants:
          (map['participants'] as List?)?.map((e) => e.toString()).toList(),
      readBy: (map['readBy'] as List?)?.map((e) => e.toString()).toList(),
      messageType: map['messageType'] ?? MessageType.text,
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      thumbnailUrl: map['thumbnailUrl'],
      status: map['status'] ?? MessageStatus.sent,
      deliveredAt: parseDateTime(map['deliveredAt']),
      readAt: parseDateTime(map['readAt']),
      metadata:
          map['metadata'] != null
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
      deletedFor:
          (map['deletedFor'] as List?)?.map((e) => e.toString()).toList(),
      deletedForEveryone: map['deletedForEveryone'] ?? false,
      deletedAt: parseDateTime(map['deletedAt']),
      isEdited: map['isEdited'] ?? false,
      lastEditedAt: parseDateTime(map['lastEditedAt']),
      editHistory:
          map['editHistory'] != null
              ? Map<String, dynamic>.from(map['editHistory'])
              : null,
      reactions: reactions,
    );
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
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'status': status,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'metadata': metadata,
      'deletedFor': deletedFor,
      'deletedForEveryone': deletedForEveryone,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'isEdited': isEdited,
      'lastEditedAt':
          lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
      'editHistory': editHistory,
      'reactions': reactions?.map((r) => r.toMap()).toList(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    List<String>? participants,
    List<String>? readBy,
    String? messageType,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    List<String>? deletedFor,
    bool? deletedForEveryone,
    DateTime? deletedAt,
    bool? isEdited,
    DateTime? lastEditedAt,
    Map<String, dynamic>? editHistory,
    List<MessageReaction>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      participants: participants ?? this.participants,
      readBy: readBy ?? this.readBy,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      deletedFor: deletedFor ?? this.deletedFor,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      deletedAt: deletedAt ?? this.deletedAt,
      isEdited: isEdited ?? this.isEdited,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      editHistory: editHistory ?? this.editHistory,
      reactions: reactions ?? this.reactions,
    );
  }

  bool get isMediaMessage => messageType != MessageType.text;
  bool get isImageMessage => messageType == MessageType.image;
  bool get isVideoMessage => messageType == MessageType.video;
  bool get isFileMessage => messageType == MessageType.file;
  bool get isAudioMessage => messageType == MessageType.audio;

  // Reaction helper methods
  bool hasReactions() => reactions != null && reactions!.isNotEmpty;
  
  int get reactionCount => reactions?.length ?? 0;
  
  List<String> get uniqueEmojis {
    if (reactions == null) return [];
    return reactions!.map((r) => r.emoji).toSet().toList();
  }
  
  int getEmojiCount(String emoji) {
    if (reactions == null) return 0;
    return reactions!.where((r) => r.emoji == emoji).length;
  }
  
  bool hasUserReacted(String userId) {
    if (reactions == null) return false;
    return reactions!.any((r) => r.userId == userId);
  }
  
  String? getUserReaction(String userId) {
    if (reactions == null) return null;
    final reaction = reactions!.firstWhere(
      (r) => r.userId == userId,
      orElse: () => MessageReaction(userId: '', emoji: '', timestamp: DateTime.now()),
    );
    return reaction.userId.isNotEmpty ? reaction.emoji : null;
  }
  
  List<MessageReaction> getReactionsForEmoji(String emoji) {
    if (reactions == null) return [];
    return reactions!.where((r) => r.emoji == emoji).toList();
  }

  // Deletion helper methods
  bool isDeletedForUser(String userId) {
    return deletedForEveryone || (deletedFor?.contains(userId) ?? false);
  }

  bool get isDeletedForEveryone => deletedForEveryone;

  bool canDeleteForEveryone(String currentUserId) {
    if (senderId != currentUserId) return false;
    if (deletedForEveryone) return false;

    // Check if message is older than 24 hours
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours <= 24;
  }

  // Edit helper methods
  bool canEdit(String currentUserId) {
    if (senderId != currentUserId) return false;
    if (deletedForEveryone) return false;
    if (messageType != MessageType.text) {
      return false; // Only text messages can be edited
    }

    // Check if message is older than 24 hours
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours <= 24;
  }

  String get editedDisplayText {
    return isEdited ? '$text (edited)' : text;
  }

  List<Map<String, dynamic>> get editHistoryList {
    if (editHistory == null) return [];

    final List<Map<String, dynamic>> history = [];
    editHistory!.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        history.add({
          'key': key,
          'text': value['text'] ?? '',
          'timestamp': value['timestamp'],
        });
      }
    });

    // Sort by timestamp
    history.sort((a, b) {
      final aTime = a['timestamp'];
      final bTime = b['timestamp'];
      if (aTime == null || bTime == null) return 0;

      if (aTime is Timestamp && bTime is Timestamp) {
        return aTime.compareTo(bTime);
      }
      return 0;
    });

    return history;
  }

  String get displayText {
    switch (messageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.file:
        return '📄 ${fileName ?? 'File'}';
      case MessageType.audio:
        return '🎵 Audio';
      default:
        return text;
    }
  }
}
