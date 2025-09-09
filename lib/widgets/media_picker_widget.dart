import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants.dart';
import '../services/media_service.dart';

class MediaPickerWidget extends StatelessWidget {
  final Function(File, String) onMediaSelected;
  final VoidCallback onCancel;

  const MediaPickerWidget({
    super.key,
    required this.onMediaSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Share Media',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Media options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () => _pickFromCamera(context),
              ),
              _buildMediaOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.green,
                onTap: () => _pickFromGallery(context),
              ),
              _buildMediaOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () => _pickVideo(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (await _validateFile(file, MessageType.image, context)) {
          onMediaSelected(file, MessageType.image);
        }
      }
    } catch (e) {
      _showError(context, 'Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (await _validateFile(file, MessageType.image, context)) {
          onMediaSelected(file, MessageType.image);
        }
      }
    } catch (e) {
      _showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final file = File(video.path);
        if (await _validateFile(file, MessageType.video, context)) {
          onMediaSelected(file, MessageType.video);
        }
      }
    } catch (e) {
      _showError(context, 'Failed to pick video: $e');
    }
  }

  Future<bool> _validateFile(
    File file,
    String fileType,
    BuildContext context,
  ) async {
    try {
      final MediaService mediaService = MediaService();

      // Check if file type is supported
      if (!mediaService.isFileTypeSupported(file.path)) {
        _showError(context, 'File type not supported');
        return false;
      }

      // Check file size
      final fileSize = await file.length();
      int maxSize;

      switch (fileType) {
        case MessageType.image:
          maxSize = AppConstants.maxImageSize;
          break;
        case MessageType.video:
          maxSize = AppConstants.maxVideoSize;
          break;
        default:
          maxSize = AppConstants.maxImageSize;
      }

      if (fileSize > maxSize) {
        final maxSizeMB = maxSize / (1024 * 1024);
        _showError(
          context,
          'File size exceeds ${maxSizeMB.toStringAsFixed(0)}MB limit',
        );
        return false;
      }

      return true;
    } catch (e) {
      _showError(context, 'Error validating file: $e');
      return false;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
