import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../services/call_service.dart';
import '../constants.dart';
import 'call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  final CallService _callService = CallService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Calls',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getCallHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading call history',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            );
          }

          final calls = snapshot.data?.docs ?? [];

          if (calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No calls yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation to make your first call',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final callDoc = calls[index];
              final call = CallModel.fromFirestore(callDoc);
              return _buildCallHistoryItem(call);
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getCallHistoryStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    // For now, just get calls where current user is the caller
    // In a real app, you'd want to combine both caller and receiver queries
    return _firestore
        .collection('calls')
        .where('callerId', isEqualTo: currentUser.uid)
        .orderBy('startTime', descending: true)
        .limit(100)
        .snapshots();
  }

  Widget _buildCallHistoryItem(CallModel call) {
    final currentUser = _auth.currentUser;
    final isOutgoing = call.callerId == currentUser?.uid;
    final otherUserName = isOutgoing ? call.receiverName : call.callerName;
    final otherUserPhoto =
        isOutgoing ? call.receiverProfilePicture : call.callerProfilePicture;
    final otherUserId = isOutgoing ? call.receiverId : call.callerId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.lightGray,
          backgroundImage:
              otherUserPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(otherUserPhoto)
                  : null,
          child:
              otherUserPhoto.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
        ),
        title: Text(
          otherUserName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.darkText,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              _getCallIcon(call, isOutgoing),
              size: 16,
              color: _getCallIconColor(call, isOutgoing),
            ),
            const SizedBox(width: 4),
            Text(
              _getCallSubtitle(call),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCallTime(call.startTime),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                call.isVideoCall ? Icons.videocam : Icons.call,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              onPressed:
                  () => _makeCall(
                    otherUserId,
                    otherUserName,
                    otherUserPhoto,
                    call.isVideoCall,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCallIcon(CallModel call, bool isOutgoing) {
    if (call.status == CallStatus.missed) {
      return isOutgoing ? Icons.call_made : Icons.call_received;
    } else if (call.status == CallStatus.declined) {
      return isOutgoing ? Icons.call_made : Icons.call_received;
    } else if (isOutgoing) {
      return Icons.call_made;
    } else {
      return Icons.call_received;
    }
  }

  Color _getCallIconColor(CallModel call, bool isOutgoing) {
    if (call.status == CallStatus.missed && !isOutgoing) {
      return Colors.red;
    } else if (call.status == CallStatus.declined) {
      return Colors.red;
    } else if (isOutgoing) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  String _getCallSubtitle(CallModel call) {
    final duration = call.duration;
    if (duration != null && duration > 0) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else if (call.status == CallStatus.missed) {
      return 'Missed';
    } else if (call.status == CallStatus.declined) {
      return 'Declined';
    } else {
      return 'No answer';
    }
  }

  String _formatCallTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  void _makeCall(
    String userId,
    String userName,
    String userPhoto,
    bool isVideoCall,
  ) async {
    try {
      // Create a UserModel for the call
      final otherUser = UserModel(
        uid: userId,
        name: userName,
        email: '', // We don't have email in call history
        photoUrl: userPhoto,
        isOnline: false, // We don't know online status
        lastSeen: DateTime.now(),
      );

      // Initialize call service
      await _callService.initialize();

      // Request permissions
      final hasPermissions = await _callService.requestPermissions(
        isVideoCall: isVideoCall,
      );

      if (!hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isVideoCall
                    ? 'Camera and microphone permissions are required for video calls'
                    : 'Microphone permission is required for voice calls',
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      // Start the call
      final call = await _callService.startCall(
        receiver: otherUser,
        callType: isVideoCall ? CallType.video : CallType.voice,
      );

      if (call != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CallScreen(call: call)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
