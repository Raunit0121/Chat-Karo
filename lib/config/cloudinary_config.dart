class CloudinaryConfig {
  // Cloudinary credentials
  static const String cloudName = 'dougea9lu';                 // ✅ Your cloud name
  static const String uploadPreset = 'profile';                // ✅ Your upload preset name
  static const String apiKey = '839836794861221';              // ✅ Your API key
  static const String apiSecret = '-5GQCXgt8yar-0-GeWi-CR8Wt2k'; // ✅ Your API secret
  
  // Optional: Environment-specific configurations
  static const bool isProduction = false;
  
  // Folder structure for organizing uploads
  static const String profileFolder = 'chatkaro/profiles';
  static const String chatFolder = 'chatkaro/chat';
  
  // Default transformation parameters
  static const int defaultProfileSize = 200;
  static const int defaultThumbnailSize = 50;
  static const int defaultChatImageSize = 400;
  
  // Validation method to check if credentials are properly set
  static bool get isConfigured {
    return cloudName != 'your_cloud_name' && 
           uploadPreset != 'your_upload_preset' && 
           apiKey != 'your_api_key' && 
           apiSecret != 'your_api_secret';
  }
  
  // Get configuration status message
  static String get configurationStatus {
    if (isConfigured) {
      return 'Cloudinary is properly configured';
    } else {
      return 'Cloudinary credentials not configured. Please update lib/config/cloudinary_config.dart with your actual credentials.';
    }
  }
} 