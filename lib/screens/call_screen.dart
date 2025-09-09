import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../constants.dart';

class CallScreen extends StatefulWidget {
  final CallModel call;

  const CallScreen({super.key, required this.call});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  final CallService _callService = CallService();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerEnabled = false;
  bool _showControls = true;
  bool _isConnecting = true;
  bool _isMinimized = false;

  Timer? _hideControlsTimer;
  Timer? _callTimer;
  int _callDuration = 0;

  int? _remoteUid;
  bool _isConnected = false;

  // Animation controllers
  late AnimationController _controlsAnimationController;
  late AnimationController _connectingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _connectingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen on during call

    // Initialize animation controllers
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _connectingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _connectingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _connectingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeOut),
    );

    _controlsAnimationController.forward();
    _connectingAnimationController.repeat(reverse: true);
    _pulseAnimationController.repeat();

    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Initialize call service
      await _callService.initialize();

      _startCallTimer();
      _setupCallListeners();
      _hideControlsAfterDelay();

      // For video calls, enable video by default
      if (widget.call.isVideoCall) {
        _enableVideo();
      }

      // Simulate connection delay
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConnected = true;
          });
          _connectingAnimationController.stop();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize call: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _callTimer?.cancel();
    _controlsAnimationController.dispose();
    _connectingAnimationController.dispose();
    _pulseAnimationController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _setupCallListeners() {
    _callService.onCallEnded = (call) {
      if (mounted) {
        Navigator.pop(context);
      }
    };
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  void _hideControlsAfterDelay() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.call.isVideoCall) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _endCall() async {
    await _callService.endCall();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService.toggleMute();
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _callService.toggleVideo();
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    _callService.enableSpeaker(_isSpeakerEnabled);
  }

  void _switchCamera() {
    _callService.switchCamera();
  }

  void _enableVideo() async {
    final engine = _callService.engine;
    if (engine != null) {
      await engine.enableVideo();
      await engine.startPreview();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getCallStatusText() {
    if (_isConnected) {
      return 'Connected';
    } else if (_isConnecting) {
      return 'Connecting...';
    } else {
      return 'Calling...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video view or voice call background
            if (widget.call.isVideoCall)
              _buildVideoView()
            else
              _buildVoiceCallView(),

            // Controls overlay
            if (_showControls || !widget.call.isVideoCall)
              _buildControlsOverlay(),

            // Tap detector for video calls to show/hide controls
            if (widget.call.isVideoCall)
              GestureDetector(
                onTap: _toggleControls,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    final engine = _callService.engine;
    if (engine == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Remote video (full screen)
        if (_remoteUid != null)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: widget.call.channelName),
            ),
          )
        else
          Container(
            color: AppColors.primaryBlue,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        widget.call.receiverProfilePicture.isNotEmpty
                            ? CachedNetworkImageProvider(
                              widget.call.receiverProfilePicture,
                            )
                            : null,
                    child:
                        widget.call.receiverProfilePicture.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.call.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // Local video (small window in corner)
        if (_isVideoEnabled)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceCallView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0d1421), Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),

            // Call status text
            Text(
              _getCallStatusText(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 40),

            // Contact avatar with pulse animation
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse animation rings
                if (!_isConnected)
                  ...List.generate(
                    3,
                    (index) => AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200 + (index * 40) * _pulseAnimation.value,
                          height: 200 + (index * 40) * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: (1 - _pulseAnimation.value) * 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Main avatar
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 77,
                    backgroundColor: Colors.grey[800],
                    backgroundImage:
                        widget.call.receiverProfilePicture.isNotEmpty
                            ? CachedNetworkImageProvider(
                              widget.call.receiverProfilePicture,
                            )
                            : null,
                    child:
                        widget.call.receiverProfilePicture.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white54,
                            )
                            : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Contact name
            Text(
              widget.call.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Call duration or status
            Text(
              _isConnected ? _formatDuration(_callDuration) : '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call info
            if (widget.call.isVideoCall)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.call.receiverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  isActive: _isMuted,
                  onTap: _toggleMute,
                ),

                // Speaker button (voice calls only)
                if (!widget.call.isVideoCall)
                  _buildControlButton(
                    icon:
                        _isSpeakerEnabled ? Icons.volume_up : Icons.volume_down,
                    isActive: _isSpeakerEnabled,
                    onTap: _toggleSpeaker,
                  ),

                // Video button (video calls only)
                if (widget.call.isVideoCall)
                  _buildControlButton(
                    icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    isActive: !_isVideoEnabled,
                    onTap: _toggleVideo,
                  ),

                // Switch camera button (video calls only)
                if (widget.call.isVideoCall)
                  _buildControlButton(
                    icon: Icons.switch_camera,
                    isActive: false,
                    onTap: _switchCamera,
                  ),

                // End call button
                _buildControlButton(
                  icon: Icons.call_end,
                  isActive: false,
                  onTap: _endCall,
                  backgroundColor: AppColors.errorRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (isActive
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3)),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
