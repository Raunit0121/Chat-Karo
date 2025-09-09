import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF075E54); // WhatsApp blue
  static const Color accentBlue = Color(
    0xFF25D366,
  ); // WhatsApp accent (greenish blue)
  static const Color white = Colors.white;
  static const Color lightGray = Color(0xFFF0F0F0); // WhatsApp light background
  static const Color darkText = Color(0xFF222222);
  static const Color lightGreen = Color(
    0xFFDFFFE2,
  ); // Soft green for login background
  static const Color lightPink = Color(
    0xFFFFE0EF,
  ); // Soft pink for signup background
  static const Color onlineGreen = Color(0xFF4CAF50); // Online status indicator
  static const Color offlineGray = Color(
    0xFF9E9E9E,
  ); // Offline status indicator
  static const Color errorRed = Color(0xFFE53E3E); // Error and delete actions
}

class CloudinaryConfig {
  // Cloudinary credentials
  static const String cloudName = 'dougea9lu';
  static const String uploadPreset = 'chatkaro';
  static const String apiKey = '974189435238585'; // Add your API key
  static const String apiSecret =
      '20mz2spe8wwfwA0Z25-ANScmX4w'; // Add your API secret

  // Upload URLs
  static const String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static const String videoUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload';
  static const String rawUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';
}

class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String video = 'video';
  static const String file = 'file';
  static const String audio = 'audio';
}

class MessageStatus {
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String read = 'read';
}

class AgoraConfig {
  // Agora App ID - Replace with your actual Agora App ID
  static const String appId = 'a316a209c1894be298a7616246282989';

  // Agora App Certificate - Replace with your actual certificate (optional for testing)
  static const String appCertificate = '395972dc4bc8407b9565303d3e5e4bd0';

  // Token expiration time (24 hours)
  static const int tokenExpirationTime = 24 * 3600;

  // Channel settings
  static const String channelPrefix = 'chatkaro_';
}

class CallType {
  static const String voice = 'voice';
  static const String video = 'video';
}

class CallStatus {
  static const String calling = 'calling';
  static const String ringing = 'ringing';
  static const String connected = 'connected';
  static const String ended = 'ended';
  static const String missed = 'missed';
  static const String declined = 'declined';
  static const String busy = 'busy';
}

class AppConstants {
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB

  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  ];
  static const List<String> supportedFileFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
  ];
}

class ReactionConstants {
  static const List<String> availableReactions = [
    '❤️',
    '😊',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
    '👎',
  ];

  static const int maxReactionsPerMessage = 50;
  static const int maxReactionsPerUser = 1; // One reaction per user per message
}
