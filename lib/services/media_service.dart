import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../constants.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  /// Upload image to Cloudinary
  Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > AppConstants.maxImageSize) {
        throw Exception(
          'Image size exceeds ${AppConstants.maxImageSize / (1024 * 1024)}MB limit',
        );
      }

      // Check file format
      final extension = path
          .extension(imageFile.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!AppConstants.supportedImageFormats.contains(extension)) {
        throw Exception('Unsupported image format: $extension');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.imageUploadUrl),
      );

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'chatkaro/images';
      request.fields['resource_type'] = 'image';

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return {
          'url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
          'width': jsonResponse['width'],
          'height': jsonResponse['height'],
          'format': jsonResponse['format'],
          'bytes': jsonResponse['bytes'],
          'thumbnail_url': _generateThumbnailUrl(jsonResponse['secure_url']),
        };
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        print('Response body: $responseData');
        throw Exception(
          'Failed to upload image: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      rethrow; // Re-throw the error so it can be caught by the calling code
    }
  }

  /// Upload video to Cloudinary
  Future<Map<String, dynamic>?> uploadVideo(File videoFile) async {
    try {
      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > AppConstants.maxVideoSize) {
        throw Exception(
          'Video size exceeds ${AppConstants.maxVideoSize / (1024 * 1024)}MB limit',
        );
      }

      // Check file format
      final extension = path
          .extension(videoFile.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!AppConstants.supportedVideoFormats.contains(extension)) {
        throw Exception('Unsupported video format: $extension');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.videoUploadUrl),
      );

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'chatkaro/videos';
      request.fields['resource_type'] = 'video';

      request.files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return {
          'url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
          'width': jsonResponse['width'],
          'height': jsonResponse['height'],
          'format': jsonResponse['format'],
          'duration': jsonResponse['duration'],
          'bytes': jsonResponse['bytes'],
          'thumbnail_url': _generateVideoThumbnailUrl(
            jsonResponse['secure_url'],
          ),
        };
      } else {
        print(
          'Cloudinary video upload failed with status: ${response.statusCode}',
        );
        print('Response body: $responseData');
        throw Exception(
          'Failed to upload video: ${response.statusCode} - $responseData',
        );
      }
    } catch (e) {
      print('Error uploading video: $e');
      rethrow; // Re-throw the error so it can be caught by the calling code
    }
  }

  /// Upload file to Cloudinary
  Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxFileSize) {
        throw Exception(
          'File size exceeds ${AppConstants.maxFileSize / (1024 * 1024)}MB limit',
        );
      }

      // Check file format
      final extension = path
          .extension(file.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!AppConstants.supportedFileFormats.contains(extension)) {
        throw Exception('Unsupported file format: $extension');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.rawUploadUrl),
      );

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'chatkaro/files';
      request.fields['resource_type'] = 'raw';

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return {
          'url': jsonResponse['secure_url'],
          'public_id': jsonResponse['public_id'],
          'format': jsonResponse['format'],
          'bytes': jsonResponse['bytes'],
          'original_filename': jsonResponse['original_filename'],
        };
      } else {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Generate thumbnail URL for images
  String _generateThumbnailUrl(String originalUrl) {
    // Extract the public ID and generate a thumbnail URL
    final parts = originalUrl.split('/');
    final uploadIndex = parts.indexOf('upload');
    if (uploadIndex != -1 && uploadIndex < parts.length - 1) {
      parts.insert(uploadIndex + 1, 'w_200,h_200,c_fill');
      return parts.join('/');
    }
    return originalUrl;
  }

  /// Generate thumbnail URL for videos
  String _generateVideoThumbnailUrl(String originalUrl) {
    // Extract the public ID and generate a video thumbnail URL
    final parts = originalUrl.split('/');
    final uploadIndex = parts.indexOf('upload');
    if (uploadIndex != -1 && uploadIndex < parts.length - 1) {
      parts.insert(uploadIndex + 1, 'w_200,h_200,c_fill,so_0');
      // Change the file extension to jpg for thumbnail
      final lastPart = parts.last;
      final dotIndex = lastPart.lastIndexOf('.');
      if (dotIndex != -1) {
        parts[parts.length - 1] = lastPart.substring(0, dotIndex) + '.jpg';
      }
      return parts.join('/');
    }
    return originalUrl;
  }

  /// Get file size in human readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file type is supported
  bool isFileTypeSupported(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceAll('.', '');
    return AppConstants.supportedImageFormats.contains(extension) ||
        AppConstants.supportedVideoFormats.contains(extension) ||
        AppConstants.supportedFileFormats.contains(extension);
  }

  /// Get file type from extension
  String getFileType(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceAll('.', '');
    if (AppConstants.supportedImageFormats.contains(extension)) {
      return MessageType.image;
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      return MessageType.video;
    } else if (AppConstants.supportedFileFormats.contains(extension)) {
      return MessageType.file;
    }
    return MessageType.file;
  }
}
