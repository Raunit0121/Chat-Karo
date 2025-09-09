import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(name);

      // Initialize notification service and get FCM token
      await _notificationService.initialize();

      // Create user model
      final userModel = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        photoUrl: '',
        bio: '',
        isOnline: true,
        fcmToken: _notificationService.fcmToken,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add user to Firestore
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userModel.toMap());
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Signup failed';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initialize notification service and update FCM token
      await _notificationService.initialize();

      // Update user online status and FCM token
      if (result.user != null) {
        await updateOnlineStatus(true);
        await updateFCMToken(_notificationService.fcmToken);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    // Update offline status before signing out
    await updateOnlineStatus(false);
    await _auth.signOut();
  }

  /// Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      await _firestore.collection('users').doc(currentUid).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Update FCM token
  Future<void> updateFCMToken(String? token) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || token == null) return;

    try {
      await _firestore.collection('users').doc(currentUid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? photoUrl,
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
        await _auth.currentUser?.updateDisplayName(name);
      }
      if (bio != null) updateData['bio'] = bio;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(currentUid).update(updateData);
    } catch (e) {
      print('Error updating profile: $e');
      throw e.toString();
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUserData() async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Stream current user data
  Stream<UserModel?> getCurrentUserStream() {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }
}
