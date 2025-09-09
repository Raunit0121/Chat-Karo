import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import '../services/media_service.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GroupService _groupService = GroupService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  List<UserModel> _allUsers = [];
  List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadUsers() async {
    _chatService.getUsers().listen((users) {
      setState(() {
        _allUsers = users;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed:
                _selectedUsers.isNotEmpty &&
                        _nameController.text.trim().isNotEmpty
                    ? _createGroup
                    : null,
            child: Text(
              'Create',
              style: TextStyle(
                color:
                    _selectedUsers.isNotEmpty &&
                            _nameController.text.trim().isNotEmpty
                        ? Colors.white
                        : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group photo section
                    Center(
                      child: GestureDetector(
                        onTap: _pickGroupImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lightGray,
                            border: Border.all(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          child:
                              _selectedImage != null
                                  ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppColors.primaryBlue,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Tap to add group photo',
                        style: TextStyle(
                          color: AppColors.offlineGray,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Group name
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Group description
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Group Description (Optional)',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primaryBlue),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Selected members
                    if (_selectedUsers.isNotEmpty) ...[
                      Text(
                        'Selected Members (${_selectedUsers.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage:
                                            user.photoUrl.isNotEmpty
                                                ? NetworkImage(user.photoUrl)
                                                : null,
                                        child:
                                            user.photoUrl.isEmpty
                                                ? Text(
                                                  user.name.isNotEmpty
                                                      ? user.name[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                : null,
                                      ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: GestureDetector(
                                          onTap: () => _removeUser(user),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: AppColors.errorRed,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // All users list
                    Text(
                      'Add Members',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final isSelected = _selectedUsers.contains(user);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                user.photoUrl.isNotEmpty
                                    ? NetworkImage(user.photoUrl)
                                    : null,
                            child:
                                user.photoUrl.isEmpty
                                    ? Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              if (value == true) {
                                _addUser(user);
                              } else {
                                _removeUser(user);
                              }
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          onTap: () {
                            if (isSelected) {
                              _removeUser(user);
                            } else {
                              _addUser(user);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  void _pickGroupImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addUser(UserModel user) {
    if (!_selectedUsers.contains(user)) {
      setState(() {
        _selectedUsers.add(user);
      });
    }
  }

  void _removeUser(UserModel user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload group image if selected
      String? profilePictureUrl;
      if (_selectedImage != null) {
        // Upload image to Cloudinary
        final uploadResult = await _mediaService.uploadImage(_selectedImage!);
        if (uploadResult != null) {
          profilePictureUrl = uploadResult['url'];
        } else {
          throw Exception('Failed to upload group image');
        }
      }

      final groupId = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        profilePicture: profilePictureUrl,
        memberIds: _selectedUsers.map((user) => user.uid).toList(),
      );

      if (mounted) {
        // Navigate to the group chat
        final group = await _groupService.getGroup(groupId);
        if (mounted) {
          if (group != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(group: group),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating group: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}
