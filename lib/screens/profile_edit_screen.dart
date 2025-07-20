import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../constants.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingImage = false;
  String? userEmail;
  String? currentPhotoUrl;
  File? selectedImageFile;
  Uint8List? selectedImageBytes; // For web compatibility

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    userEmail = user.email;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      bioController.text = data['bio'] ?? '';
      // Try to get photo URL from both field names
      currentPhotoUrl = data['profile image'] ?? data['photoUrl'] ?? '';
    } else {
      nameController.text = user.displayName ?? '';
      bioController.text = '';
      currentPhotoUrl = '';
    }
    setState(() => isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            selectedImageBytes = bytes;
            selectedImageFile = null;
          });
        } else {
          // For mobile, use File
          setState(() {
            selectedImageFile = File(image.path);
            selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            selectedImageBytes = bytes;
            selectedImageFile = null;
          });
        } else {
          // For mobile, use File
          setState(() {
            selectedImageFile = File(image.path);
            selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage() async {
    if (selectedImageFile == null && selectedImageBytes == null) return;
    
    setState(() => isUploadingImage = true);
    try {
      final cloudinaryService = CloudinaryService();
      final publicId = 'profile_${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
      String imageUrl;
      if (kIsWeb && selectedImageBytes != null) {
        // For web, upload bytes directly
        imageUrl = await cloudinaryService.uploadImageBytes(selectedImageBytes!, publicId: publicId);
      } else {
        // For mobile, upload file
        imageUrl = await cloudinaryService.uploadImage(selectedImageFile!, publicId: publicId);
      }
      
      // Update the current photo URL immediately
      setState(() {
        currentPhotoUrl = imageUrl;
        selectedImageFile = null;
        selectedImageBytes = null;
      });
      
      // Save the image URL to Firebase immediately
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoUrl': imageUrl,
          'profile image': imageUrl, // Store with both field names for compatibility
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture uploaded and saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => isSaving = true);
    try {
      // Upload image first if selected
      String? finalPhotoUrl = currentPhotoUrl;
      if (selectedImageFile != null || selectedImageBytes != null) {
        await _uploadProfileImage();
        finalPhotoUrl = currentPhotoUrl;
      }
      
      // Save profile data to Firebase
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
        'photoUrl': finalPhotoUrl ?? '',
        'profile image': finalPhotoUrl ?? '', // Store with both field names
      });
      
      // Update Firebase Auth display name
      await user.updateDisplayName(nameController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Background circles
          Positioned(
            left: -100,
            top: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -120,
            bottom: -60,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          if (!isLoading)
            SingleChildScrollView(
              child: Column(
                children: [
                // Custom AppBar
                Container(
                  padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryBlue,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: kIsWeb
                                        ? (selectedImageBytes != null
                                            ? Image.memory(
                                                selectedImageBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty
                                                ? Image.network(
                                                    currentPhotoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      // Custom placeholder icon
                                                      return Container(
                                                        color: AppColors.lightGray,
                                                        child: const Icon(
                                                          Icons.account_circle,
                                                          size: 80,
                                                          color: Colors.teal,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: AppColors.lightGray,
                                                    child: const Icon(
                                                      Icons.account_circle,
                                                      size: 80,
                                                      color: Colors.teal,
                                                    ),
                                                  )))
                                        : (selectedImageFile != null
                                            ? Image.file(
                                                selectedImageFile!,
                                                fit: BoxFit.cover,
                                              )
                                            : (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty
                                                ? Image.network(
                                                    currentPhotoUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        color: AppColors.lightGray,
                                                        child: const Icon(
                                                          Icons.account_circle,
                                                          size: 80,
                                                          color: Colors.teal,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: AppColors.lightGray,
                                                    child: const Icon(
                                                      Icons.account_circle,
                                                      size: 80,
                                                      color: Colors.teal,
                                                    ),
                                                  ))),
                                  ),
                                ),
                                if (isUploadingImage)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: _showImagePickerDialog,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _showImagePickerDialog,
                              child: const Text(
                                'Change Profile Picture',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Email',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userEmail ?? '',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Name',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          border: UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black87, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Bio',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      TextField(
                        controller: bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tell us about yourself',
                          border: UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black87, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isSaving ? null : _saveProfile,
                            child: isSaving
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save',
                                    style: TextStyle(fontSize: 22, color: Colors.white, letterSpacing: 1),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(fontSize: 18, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 