import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/media_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileEditScreen({Key? key, this.user}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final AuthService _authService = AuthService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _imagePicker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;
  String? userEmail;
  String? _profileImageUrl;
  File? _selectedImage;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.user != null) {
      // Use provided user data
      _currentUser = widget.user;
      nameController.text = widget.user!.name;
      bioController.text = widget.user!.bio;
      userEmail = widget.user!.email;
      _profileImageUrl = widget.user!.photoUrl;
      setState(() => isLoading = false);
      return;
    }

    // Load from auth service
    final userData = await _authService.getCurrentUserData();
    if (userData != null) {
      _currentUser = userData;
      nameController.text = userData.name;
      bioController.text = userData.bio;
      userEmail = userData.email;
      _profileImageUrl = userData.photoUrl;
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email;
        nameController.text = user.displayName ?? '';
        bioController.text = '';
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_profileImageUrl?.isNotEmpty == true ||
                  _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _profileImageUrl = '';
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);
    try {
      String? newPhotoUrl = _profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadResult = await _mediaService.uploadImage(_selectedImage!);
        if (uploadResult != null) {
          newPhotoUrl = uploadResult['url'];
        } else {
          throw Exception('Failed to upload profile image');
        }
      }

      // Update profile using auth service
      await _authService.updateProfile(
        name: nameController.text.trim(),
        bio: bioController.text.trim(),
        photoUrl: newPhotoUrl,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.accentBlue,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
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
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (!isLoading)
            SingleChildScrollView(
              child: Column(
                children: [
                  // Custom AppBar
                  Container(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
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
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.darkText,
                          ),
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
                        // Profile Image Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.lightGray,
                                backgroundImage:
                                    _selectedImage != null
                                        ? FileImage(_selectedImage!)
                                        : (_profileImageUrl?.isNotEmpty == true
                                                ? NetworkImage(
                                                  _profileImageUrl!,
                                                )
                                                : null)
                                            as ImageProvider?,
                                child:
                                    (_selectedImage == null &&
                                            _profileImageUrl?.isEmpty != false)
                                        ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.darkText,
                                        )
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            userEmail ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
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
                              borderSide: BorderSide(
                                color: Colors.black87,
                                width: 1.5,
                              ),
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
                          maxLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Tell us about yourself',
                            border: UnderlineInputBorder(),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black87,
                                width: 1.5,
                              ),
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
                              child:
                                  isSaving
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
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
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
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
