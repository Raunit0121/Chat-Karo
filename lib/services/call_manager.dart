import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/call_model.dart';
import '../services/call_service.dart';
import '../screens/incoming_call_screen.dart';

class CallManager {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  final CallService _callService = CallService();
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  BuildContext? _context;

  // Initialize the call manager
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _context = context;

    // Initialize Agora
    await _callService.initialize();

    // Set up call event handlers
    _callService.onIncomingCall = _handleIncomingCall;
    _callService.onCallEnded = _handleCallEnded;
    _callService.onError = _handleCallError;

    // Listen for auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _callService.listenForIncomingCalls();
      }
    });

    _isInitialized = true;
  }

  // Handle incoming call
  void _handleIncomingCall(CallModel call) {
    if (_context != null && _context!.mounted) {
      // Show incoming call screen
      showDialog(
        context: _context!,
        barrierDismissible: false,
        builder: (context) => IncomingCallScreen(call: call),
      );
    }
  }

  // Handle call ended
  void _handleCallEnded(CallModel call) {
    // You can add any cleanup logic here
    print('Call ended: ${call.id}');
  }

  // Handle call errors
  void _handleCallError(String error) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('Call error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update context when navigating
  void updateContext(BuildContext context) {
    _context = context;
  }

  // Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _callService.dispose();
    _isInitialized = false;
  }

  // Get call service instance
  CallService get callService => _callService;
}
