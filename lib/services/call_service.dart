import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../constants.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RtcEngine? _engine;
  StreamSubscription<DocumentSnapshot>? _callSubscription;
  CallModel? _currentCall;

  // Callbacks
  Function(CallModel)? onIncomingCall;
  Function(CallModel)? onCallEnded;
  Function(CallModel)? onCallConnected;
  Function(String)? onError;

  // Initialize Agora engine
  Future<void> initialize() async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      // Set up event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Successfully joined channel: ${connection.channelId}');
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('Remote user joined: $remoteUid');
            _updateCallStatus(CallStatus.connected);
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            print('Remote user left: $remoteUid');
            endCall();
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print('Left channel');
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err - $msg');
            onError?.call('Call error: $msg');
          },
        ),
      );
    } catch (e) {
      print('Error initializing Agora: $e');
      onError?.call('Failed to initialize calling service');
    }
  }

  // Request necessary permissions
  Future<bool> requestPermissions({required bool isVideoCall}) async {
    List<Permission> permissions = [Permission.microphone];
    if (isVideoCall) {
      permissions.add(Permission.camera);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Generate a unique channel name
  String _generateChannelName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return '${AgoraConfig.channelPrefix}${timestamp}_$random';
  }

  // Start a call
  Future<CallModel?> startCall({
    required UserModel receiver,
    required String callType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        onError?.call('User not authenticated');
        return null;
      }

      // Request permissions
      final hasPermissions = await requestPermissions(
        isVideoCall: callType == CallType.video,
      );
      if (!hasPermissions) {
        onError?.call('Permissions not granted');
        return null;
      }

      // Get current user data
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create call model
      final channelName = _generateChannelName();
      final call = CallModel(
        id: '', // Will be set by Firestore
        callerId: currentUser.uid,
        callerName: userData['name'] ?? 'Unknown',
        callerProfilePicture: userData['photoUrl'] ?? '',
        receiverId: receiver.uid,
        receiverName: receiver.name,
        receiverProfilePicture: receiver.photoUrl,
        channelName: channelName,
        callType: callType,
        status: CallStatus.calling,
        startTime: DateTime.now(),
        participants: [currentUser.uid, receiver.uid],
      );

      // Save call to Firestore
      final callDoc = await _firestore.collection('calls').add(call.toMap());
      _currentCall = call.copyWith(id: callDoc.id);

      // Join Agora channel
      await _joinChannel(channelName, currentUser.uid.hashCode);

      // Listen for call updates
      _listenToCallUpdates(callDoc.id);

      return _currentCall;
    } catch (e) {
      print('Error starting call: $e');
      onError?.call('Failed to start call');
      return null;
    }
  }

  // Answer an incoming call
  Future<void> answerCall(CallModel call) async {
    try {
      final hasPermissions = await requestPermissions(
        isVideoCall: call.isVideoCall,
      );
      if (!hasPermissions) {
        onError?.call('Permissions not granted');
        return;
      }

      // Update call status
      await _firestore.collection('calls').doc(call.id).update({
        'status': CallStatus.connected,
      });

      // Join Agora channel
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _joinChannel(call.channelName, currentUser.uid.hashCode);
        _currentCall = call.copyWith(status: CallStatus.connected);
        _listenToCallUpdates(call.id);
      }
    } catch (e) {
      print('Error answering call: $e');
      onError?.call('Failed to answer call');
    }
  }

  // Decline a call
  Future<void> declineCall(CallModel call) async {
    try {
      await _firestore.collection('calls').doc(call.id).update({
        'status': CallStatus.declined,
        'endTime': Timestamp.now(),
      });
    } catch (e) {
      print('Error declining call: $e');
    }
  }

  // End current call
  Future<void> endCall() async {
    try {
      if (_currentCall != null) {
        final duration =
            DateTime.now().difference(_currentCall!.startTime).inSeconds;

        await _firestore.collection('calls').doc(_currentCall!.id).update({
          'status': CallStatus.ended,
          'endTime': Timestamp.now(),
          'duration': duration,
        });

        await _leaveChannel();
        _currentCall = null;
        _callSubscription?.cancel();
      }
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Join Agora channel
  Future<void> _joinChannel(String channelName, int uid) async {
    try {
      await _engine?.joinChannel(
        token:
            '', // Use null for testing, implement token server for production
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      print('Error joining channel: $e');
      onError?.call('Failed to join call');
    }
  }

  // Leave Agora channel
  Future<void> _leaveChannel() async {
    try {
      await _engine?.leaveChannel();
    } catch (e) {
      print('Error leaving channel: $e');
    }
  }

  // Listen to call updates
  void _listenToCallUpdates(String callId) {
    _callSubscription = _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final call = CallModel.fromFirestore(snapshot);
            _currentCall = call;

            if (call.status == CallStatus.connected) {
              onCallConnected?.call(call);
            } else if (call.isEnded) {
              onCallEnded?.call(call);
              _leaveChannel();
              _currentCall = null;
              _callSubscription?.cancel();
            }
          }
        });
  }

  // Update call status
  Future<void> _updateCallStatus(String status) async {
    if (_currentCall != null) {
      await _firestore.collection('calls').doc(_currentCall!.id).update({
        'status': status,
      });
    }
  }

  // Listen for incoming calls
  void listenForIncomingCalls() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: CallStatus.calling)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            final call = CallModel.fromFirestore(doc);
            onIncomingCall?.call(call);
          }
        });
  }

  // Toggle mute
  Future<void> toggleMute() async {
    await _engine?.muteLocalAudioStream(true);
  }

  // Toggle video
  Future<void> toggleVideo() async {
    await _engine?.muteLocalVideoStream(true);
  }

  // Switch camera
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  // Enable speaker
  Future<void> enableSpeaker(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  // Get Agora engine for UI rendering
  RtcEngine? get engine => _engine;

  // Get current call
  CallModel? get currentCall => _currentCall;

  // Dispose
  void dispose() {
    _callSubscription?.cancel();
    _engine?.release();
  }
}
