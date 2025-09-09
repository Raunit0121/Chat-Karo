import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupRole {
  admin,
  member,
}

class GroupSettings {
  final bool onlyAdminsCanSendMessages;
  final bool onlyAdminsCanAddMembers;
  final bool onlyAdminsCanEditGroupInfo;
  final bool disappearingMessages;
  final int? disappearingMessagesDuration; // in hours
  final int maxMembers;

  const GroupSettings({
    this.onlyAdminsCanSendMessages = false,
    this.onlyAdminsCanAddMembers = false,
    this.onlyAdminsCanEditGroupInfo = true,
    this.disappearingMessages = false,
    this.disappearingMessagesDuration,
    this.maxMembers = 256,
  });

  Map<String, dynamic> toMap() {
    return {
      'onlyAdminsCanSendMessages': onlyAdminsCanSendMessages,
      'onlyAdminsCanAddMembers': onlyAdminsCanAddMembers,
      'onlyAdminsCanEditGroupInfo': onlyAdminsCanEditGroupInfo,
      'disappearingMessages': disappearingMessages,
      'disappearingMessagesDuration': disappearingMessagesDuration,
      'maxMembers': maxMembers,
    };
  }

  factory GroupSettings.fromMap(Map<String, dynamic> map) {
    return GroupSettings(
      onlyAdminsCanSendMessages: map['onlyAdminsCanSendMessages'] ?? false,
      onlyAdminsCanAddMembers: map['onlyAdminsCanAddMembers'] ?? false,
      onlyAdminsCanEditGroupInfo: map['onlyAdminsCanEditGroupInfo'] ?? true,
      disappearingMessages: map['disappearingMessages'] ?? false,
      disappearingMessagesDuration: map['disappearingMessagesDuration'],
      maxMembers: map['maxMembers'] ?? 256,
    );
  }

  GroupSettings copyWith({
    bool? onlyAdminsCanSendMessages,
    bool? onlyAdminsCanAddMembers,
    bool? onlyAdminsCanEditGroupInfo,
    bool? disappearingMessages,
    int? disappearingMessagesDuration,
    int? maxMembers,
  }) {
    return GroupSettings(
      onlyAdminsCanSendMessages: onlyAdminsCanSendMessages ?? this.onlyAdminsCanSendMessages,
      onlyAdminsCanAddMembers: onlyAdminsCanAddMembers ?? this.onlyAdminsCanAddMembers,
      onlyAdminsCanEditGroupInfo: onlyAdminsCanEditGroupInfo ?? this.onlyAdminsCanEditGroupInfo,
      disappearingMessages: disappearingMessages ?? this.disappearingMessages,
      disappearingMessagesDuration: disappearingMessagesDuration ?? this.disappearingMessagesDuration,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? profilePicture;
  final List<String> members;
  final List<String> admins;
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastActivity;
  final GroupSettings settings;
  final int memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.profilePicture,
    required this.members,
    required this.admins,
    required this.createdBy,
    required this.createdAt,
    required this.lastActivity,
    required this.settings,
    required this.memberCount,
  });

  // Helper methods
  bool isAdmin(String userId) => admins.contains(userId);
  bool isMember(String userId) => members.contains(userId);
  
  GroupRole getUserRole(String userId) {
    if (isAdmin(userId)) return GroupRole.admin;
    return GroupRole.member;
  }

  bool canSendMessages(String userId) {
    if (!isMember(userId)) return false;
    if (settings.onlyAdminsCanSendMessages) {
      return isAdmin(userId);
    }
    return true;
  }

  bool canAddMembers(String userId) {
    if (!isMember(userId)) return false;
    if (settings.onlyAdminsCanAddMembers) {
      return isAdmin(userId);
    }
    return true;
  }

  bool canEditGroupInfo(String userId) {
    if (!isMember(userId)) return false;
    if (settings.onlyAdminsCanEditGroupInfo) {
      return isAdmin(userId);
    }
    return true;
  }

  bool canRemoveMembers(String userId) {
    return isAdmin(userId);
  }

  bool canMakeAdmin(String userId) {
    return isAdmin(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'profilePicture': profilePicture,
      'members': members,
      'admins': admins,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivity': Timestamp.fromDate(lastActivity),
      'settings': settings.toMap(),
      'memberCount': memberCount,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      profilePicture: map['profilePicture'],
      members: List<String>.from(map['members'] ?? []),
      admins: List<String>.from(map['admins'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActivity: (map['lastActivity'] as Timestamp).toDate(),
      settings: GroupSettings.fromMap(map['settings'] ?? {}),
      memberCount: map['memberCount'] ?? 0,
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? profilePicture,
    List<String>? members,
    List<String>? admins,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastActivity,
    GroupSettings? settings,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      profilePicture: profilePicture ?? this.profilePicture,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      settings: settings ?? this.settings,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
