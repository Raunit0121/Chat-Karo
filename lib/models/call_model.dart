import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String callerProfilePicture;
  final String receiverId;
  final String receiverName;
  final String receiverProfilePicture;
  final String channelName;
  final String callType; // voice or video
  final String status; // calling, ringing, connected, ended, missed, declined
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final bool isGroupCall;
  final List<String> participants;

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerProfilePicture,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfilePicture,
    required this.channelName,
    required this.callType,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    this.isGroupCall = false,
    this.participants = const [],
  });

  // Create a call model from Firestore document
  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallModel(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerProfilePicture: data['callerProfilePicture'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverProfilePicture: data['receiverProfilePicture'] ?? '',
      channelName: data['channelName'] ?? '',
      callType: data['callType'] ?? CallType.voice,
      status: data['status'] ?? CallStatus.calling,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      duration: data['duration'],
      isGroupCall: data['isGroupCall'] ?? false,
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerProfilePicture': callerProfilePicture,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverProfilePicture': receiverProfilePicture,
      'channelName': channelName,
      'callType': callType,
      'status': status,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'isGroupCall': isGroupCall,
      'participants': participants,
    };
  }

  // Copy with method for updating call data
  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerProfilePicture,
    String? receiverId,
    String? receiverName,
    String? receiverProfilePicture,
    String? channelName,
    String? callType,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? isGroupCall,
    List<String>? participants,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerProfilePicture: callerProfilePicture ?? this.callerProfilePicture,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverProfilePicture: receiverProfilePicture ?? this.receiverProfilePicture,
      channelName: channelName ?? this.channelName,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      participants: participants ?? this.participants,
    );
  }

  // Helper getters
  bool get isVoiceCall => callType == CallType.voice;
  bool get isVideoCall => callType == CallType.video;
  bool get isActive => status == CallStatus.calling || 
                      status == CallStatus.ringing || 
                      status == CallStatus.connected;
  bool get isEnded => status == CallStatus.ended || 
                     status == CallStatus.missed || 
                     status == CallStatus.declined;

  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
