import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:crypto/crypto.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // Use credentials from config file
  static const String _cloudName = CloudinaryConfig.cloudName;
  static const String _uploadPreset = CloudinaryConfig.uploadPreset;
  static const String _apiKey = CloudinaryConfig.apiKey;
  static const String _apiSecret = CloudinaryConfig.apiSecret;

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Upload image to Cloudinary and return the URL
  Future<String> uploadImage(File imageFile, {String? publicId, String folder = CloudinaryConfig.profileFolder}) async {
    // Validate configuration
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary not configured. ${CloudinaryConfig.configurationStatus}');
    }
    
    // Validate file
    if (!imageFile.existsSync()) {
      throw Exception('Image file does not exist');
    }
    
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          publicId: publicId,
          folder: folder,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload image bytes to Cloudinary (for web compatibility)
  Future<String> uploadImageBytes(Uint8List imageBytes, {String? publicId, String folder = CloudinaryConfig.profileFolder}) async {
    // Validate configuration
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary not configured. ${CloudinaryConfig.configurationStatus}');
    }
    
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );
      
      // Add form fields
      request.fields['upload_preset'] = _uploadPreset;
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }
      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }
      
      // Add image bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }


  /// Get optimized profile picture URL with transformations
  String getProfilePictureUrl(String publicId, {int size = CloudinaryConfig.defaultProfileSize}) {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary not configured. ${CloudinaryConfig.configurationStatus}');
    }
    if (publicId.isEmpty) {
      throw Exception('Public ID cannot be empty');
    }
    return 'https://res.cloudinary.com/$_cloudName/image/upload/c_fill,g_face,h_$size,w_$size,f_auto,q_auto/$publicId';
  }

  /// Get thumbnail URL for profile pictures
  String getThumbnailUrl(String publicId, {int size = CloudinaryConfig.defaultThumbnailSize}) {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary not configured. ${CloudinaryConfig.configurationStatus}');
    }
    if (publicId.isEmpty) {
      throw Exception('Public ID cannot be empty');
    }
    return 'https://res.cloudinary.com/$_cloudName/image/upload/c_fill,g_face,h_$size,w_$size,f_auto,q_auto/$publicId';
  }

  /// Get optimized chat image URL
  String getChatImageUrl(String publicId, {int size = CloudinaryConfig.defaultChatImageSize}) {
    if (!CloudinaryConfig.isConfigured) {
      throw Exception('Cloudinary not configured. ${CloudinaryConfig.configurationStatus}');
    }
    if (publicId.isEmpty) {
      throw Exception('Public ID cannot be empty');
    }
    return 'https://res.cloudinary.com/$_cloudName/image/upload/c_limit,h_$size,w_$size,f_auto,q_auto/$publicId';
  }

  /// Delete image from Cloudinary
  Future<void> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(publicId, timestamp);
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Generate signature for authenticated requests
  String _generateSignature(String publicId, int timestamp) {
    final params = {
      'public_id': publicId,
      'timestamp': timestamp.toString(),
    };
    
    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    // Create query string
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    // Add API secret
    final signatureString = queryString + _apiSecret;
    
    // Generate proper SHA-1 hash
    final bytes = utf8.encode(signatureString);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicId(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3 && pathSegments[0] == 'upload') {
        // Remove the upload/transformation part and get the public ID
        final publicIdParts = pathSegments.skip(2);
        return publicIdParts.join('/');
      }
    } catch (e) {
      print('Error extracting public ID: $e');
    }
    return null;
  }

  /// Test Cloudinary configuration
  Future<bool> testConfiguration() async {
    try {
      if (!CloudinaryConfig.isConfigured) {
        print('❌ Cloudinary not configured: ${CloudinaryConfig.configurationStatus}');
        return false;
      }
      
      // Test URL generation
      final testUrl = getProfilePictureUrl('test', size: 100);
      print('✅ Cloudinary configuration test passed');
      print('📝 Test URL: $testUrl');
      return true;
    } catch (e) {
      print('❌ Cloudinary configuration test failed: $e');
      return false;
    }
  }
} 