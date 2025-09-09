import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new group
  Future<String> createGroup({
    required String name,
    String? description,
    String? profilePicture,
    required List<String> memberIds,
    GroupSettings? settings,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final groupId = _firestore.collection('groups').doc().id;
    final now = DateTime.now();

    // Ensure creator is in members and admins
    final members = [...memberIds];
    if (!members.contains(currentUser.uid)) {
      members.add(currentUser.uid);
    }

    final group = GroupModel(
      id: groupId,
      name: name,
      description: description,
      profilePicture: profilePicture,
      members: members,
      admins: [currentUser.uid], // Creator is the first admin
      createdBy: currentUser.uid,
      createdAt: now,
      lastActivity: now,
      settings: settings ?? const GroupSettings(),
      memberCount: members.length,
    );

    await _firestore.collection('groups').doc(groupId).set(group.toMap());

    // Send system message about group creation
    await _sendSystemMessage(
      groupId: groupId,
      message: 'Group created',
      participants: members,
    );

    return groupId;
  }

  // Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  // Get groups for current user
  Stream<List<GroupModel>> getUserGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('DEBUG: No current user for getUserGroups');
      return Stream.value([]);
    }

    print('DEBUG: Getting groups for user: ${currentUser.uid}');

    // Try the optimized query first, fallback to simple query if index not ready
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .orderBy('lastActivity', descending: true)
        .snapshots()
        .handleError((error) {
          print('Groups query error (likely index building): $error');
          // Fallback to simple query without ordering
          return _firestore
              .collection('groups')
              .where('members', arrayContains: currentUser.uid)
              .snapshots();
        })
        .map((snapshot) {
          print(
            'DEBUG: Groups query returned ${snapshot.docs.length} documents',
          );
          final groups =
              snapshot.docs.map((doc) {
                  print('DEBUG: Group document: ${doc.id} - ${doc.data()}');
                  return GroupModel.fromMap(doc.data());
                }).toList()
                ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
          print('DEBUG: Processed ${groups.length} groups');
          return groups;
        }); // Sort in memory
  }

  // Fallback method for when index is not ready
  Stream<List<GroupModel>> getUserGroupsSimple() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUser.uid)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => GroupModel.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity)),
        ); // Sort in memory
  }

  // Add members to group
  Future<void> addMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.canAddMembers(currentUser.uid)) {
      throw 'You do not have permission to add members';
    }

    // Check member limit
    final newMemberCount = group.members.length + memberIds.length;
    if (newMemberCount > group.settings.maxMembers) {
      throw 'Group member limit exceeded';
    }

    // Add new members
    final updatedMembers = [...group.members];
    for (final memberId in memberIds) {
      if (!updatedMembers.contains(memberId)) {
        updatedMembers.add(memberId);
      }
    }

    await _firestore.collection('groups').doc(groupId).update({
      'members': updatedMembers,
      'memberCount': updatedMembers.length,
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Send system message
    await _sendSystemMessage(
      groupId: groupId,
      message: 'Members added to the group',
      participants: updatedMembers,
    );
  }

  // Remove member from group
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    // Check permissions
    if (!group.canRemoveMembers(currentUser.uid) &&
        currentUser.uid != memberId) {
      throw 'You do not have permission to remove members';
    }

    // Cannot remove the last admin
    if (group.isAdmin(memberId) && group.admins.length == 1) {
      throw 'Cannot remove the last admin';
    }

    final updatedMembers = group.members.where((id) => id != memberId).toList();
    final updatedAdmins = group.admins.where((id) => id != memberId).toList();

    await _firestore.collection('groups').doc(groupId).update({
      'members': updatedMembers,
      'admins': updatedAdmins,
      'memberCount': updatedMembers.length,
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Send system message
    await _sendSystemMessage(
      groupId: groupId,
      message:
          currentUser.uid == memberId ? 'Left the group' : 'Member removed',
      participants: updatedMembers,
    );
  }

  // Make member admin
  Future<void> makeAdmin({
    required String groupId,
    required String memberId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.canMakeAdmin(currentUser.uid)) {
      throw 'You do not have permission to make admins';
    }

    if (!group.isMember(memberId)) {
      throw 'User is not a member of this group';
    }

    if (group.isAdmin(memberId)) {
      throw 'User is already an admin';
    }

    final updatedAdmins = [...group.admins, memberId];

    await _firestore.collection('groups').doc(groupId).update({
      'admins': updatedAdmins,
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Send system message
    await _sendSystemMessage(
      groupId: groupId,
      message: 'New admin added',
      participants: group.members,
    );
  }

  // Remove admin (demote to member)
  Future<void> removeAdmin({
    required String groupId,
    required String adminId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.isAdmin(currentUser.uid)) {
      throw 'You do not have permission to remove admins';
    }

    if (group.admins.length == 1) {
      throw 'Cannot remove the last admin';
    }

    final updatedAdmins = group.admins.where((id) => id != adminId).toList();

    await _firestore.collection('groups').doc(groupId).update({
      'admins': updatedAdmins,
      'lastActivity': FieldValue.serverTimestamp(),
    });

    // Send system message
    await _sendSystemMessage(
      groupId: groupId,
      message: 'Admin removed',
      participants: group.members,
    );
  }

  // Update group info
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? profilePicture,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.canEditGroupInfo(currentUser.uid)) {
      throw 'You do not have permission to edit group info';
    }

    final updates = <String, dynamic>{
      'lastActivity': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (profilePicture != null) updates['profilePicture'] = profilePicture;

    await _firestore.collection('groups').doc(groupId).update(updates);
  }

  // Update group settings
  Future<void> updateGroupSettings({
    required String groupId,
    required GroupSettings settings,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.isAdmin(currentUser.uid)) {
      throw 'Only admins can change group settings';
    }

    await _firestore.collection('groups').doc(groupId).update({
      'settings': settings.toMap(),
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw 'User not authenticated';

    final group = await getGroup(groupId);
    if (group == null) throw 'Group not found';

    if (!group.isAdmin(currentUser.uid)) {
      throw 'Only admins can delete the group';
    }

    await _firestore.collection('groups').doc(groupId).delete();
  }

  // Send system message
  Future<void> _sendSystemMessage({
    required String groupId,
    required String message,
    required List<String> participants,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return; // Skip system message if user not authenticated
    }

    final messageId = _firestore.collection('chats').doc().id;

    await _firestore.collection('chats').doc(messageId).set({
      'id': messageId,
      'senderId': currentUser.uid, // Use current user's UID instead of 'system'
      'receiverId': groupId,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
      'participants': participants,
      'messageType': 'text', // Use messageType instead of type for consistency
      'type': 'system', // Keep type for system message identification
      'groupId': groupId,
      'isGroupMessage': true,
      'readBy': [currentUser.uid], // Mark as read by sender
      'status': 'sent',
    });
  }
}
