import 'dart:convert';
import 'dart:io';

import 'package:donation_app/models/user_model.dart' as user_model;
import 'package:donation_app/providers/user_provider.dart';
import 'package:donation_app/screens/org/org_profileheader.dart';
import 'package:donation_app/screens/shared/image_viewer.dart';
import 'package:donation_app/utils/image_compression.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class OrgProfilePage extends StatefulWidget {
  final String mode; // edit, view
  const OrgProfilePage({Key? key, required this.mode}) : super(key: key);

  @override
  State<OrgProfilePage> createState() => OrgProfilePageState();
}

class OrgProfilePageState extends State<OrgProfilePage> {
  late User? _currentUser;
  late Future<DocumentSnapshot> _userDocFuture;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _localProfileImageBase64;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _descriptionController;
  late List<TextEditingController> _addressControllers;
  late TextEditingController _contactNumController;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.mode == "edit";

    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressControllers = [TextEditingController()];
    _contactNumController = TextEditingController();
    _isOpen = false;

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userDocFuture =
          context.read<MyAuthProvider>().getUserById(_currentUser!.uid);
      _getUserDetails();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    for (var controller in _addressControllers) {
      controller.dispose();
    }
    _contactNumController.dispose();
    super.dispose();
  }

  Future<void> _getUserDetails() async {
    final DocumentSnapshot userSnapshot = await _userDocFuture;
    final userData =
        user_model.User.fromJson(userSnapshot.data() as Map<String, dynamic>);

    if (!mounted) return;
    setState(() {
      _nameController.text = userData.name;
      _usernameController.text = userData.username;
      _descriptionController.text = userData.description;
      _addressControllers = userData.addresses
          .map((address) => TextEditingController(text: address))
          .toList();
      _contactNumController.text = userData.contactNum;
      _isOpen = userData.isOpen;
    });
  }

  void _initializeControllers(user_model.User profile) {
    _nameController.text = profile.name;
    _usernameController.text = profile.username;
    _descriptionController.text = profile.description;
    _contactNumController.text = profile.contactNum;
    _isOpen = profile.isOpen;
    _addressControllers = profile.addresses
        .map((addr) => TextEditingController(text: addr))
        .toList();
    if (_addressControllers.isEmpty) {
      _addressControllers.add(TextEditingController());
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final compressedBytes = await ImageCompressionUtil.compressImage(file);
      final base64Image = base64Encode(compressedBytes);

      if (mounted) {
        setState(() {
          _localProfileImageBase64 = base64Image;
        });
      }
    }
  }

  void _viewProfileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShowFullImage(image: imageUrl),
      ),
    );
  }

  Future<bool?> _showCancelEditDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          title: const Text('Are you sure you want to leave?'),
          content: const Text('Any unsaved changes will be lost.'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveOrgProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final contact = _contactNumController.text.trim();
    final addresses = _addressControllers
        .map((c) => c.text.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    if (description.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description is required')),
        );
      }
      return;
    }

    if (contact.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact number is required')),
        );
      }
      return;
    }

    if (addresses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one address is required')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final imageUrl = _localProfileImageBase64;

    context.read<MyAuthProvider>().editOrgDetails(
          _currentUser!.uid,
          description,
          addresses,
          contact,
          _isOpen,
          imageUrl,
        );

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
          _localProfileImageBase64 = null;
        });
        _userDocFuture =
            context.read<MyAuthProvider>().getUserById(_currentUser!.uid);
        _getUserDetails();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelEdit() async {
    final shouldCancel = await _showCancelEditDialog() ?? false;
    if (!context.mounted || !shouldCancel) return;

    try {
      final DocumentSnapshot userSnapshot = await _userDocFuture;
      final userData =
          user_model.User.fromJson(userSnapshot.data() as Map<String, dynamic>);

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _localProfileImageBase64 = null;
        _initializeControllers(userData);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel edit: $e')),
        );
      }
    }
  }

  void _addAddress() {
    setState(() {
      _addressControllers.add(TextEditingController());
    });
  }

  void _removeAddress(int index) {
    if (_addressControllers.length > 1) {
      setState(() {
        _addressControllers[index].dispose();
        _addressControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isEditing,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final bool shouldCancel = await _showCancelEditDialog() ?? false;
        if (context.mounted && shouldCancel) {
          setState(() => _isEditing = false);
          _userDocFuture =
              context.read<MyAuthProvider>().getUserById(_currentUser!.uid);
          _getUserDetails();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          iconTheme: IconThemeData(color: colorScheme.primary),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<MyAuthProvider>().signOut(),
                tooltip: 'Logout',
              ),
          ],
        ),
        body: _currentUser == null
            ? const Center(child: Text('No user is currently signed in'))
            : FutureBuilder<DocumentSnapshot>(
                future: _userDocFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64,
                              color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {
                              _userDocFuture =
                                  context.read<MyAuthProvider>()
                                      .getUserById(_currentUser!.uid);
                              _getUserDetails();
                            }),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('User not found'));
                  } else {
                    final userData =
                        user_model.User.fromJson(snapshot.data!.data() as Map<String, dynamic>);

                    final displayName = _isEditing ? _nameController.text : userData.name;
                    final displayUsername =
                        _isEditing ? _usernameController.text : userData.username;
                    final displayContact =
                        _isEditing ? _contactNumController.text : userData.contactNum;
                    final displayDescription =
                        _isEditing ? _descriptionController.text : userData.description;
                    final displayAddresses =
                        _isEditing
                            ? _addressControllers.map((c) => c.text).toList()
                            : userData.addresses;
                    final displayImageUrl =
                        _localProfileImageBase64 ?? userData.profileImageUrl;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            OrgProfileHeader(
                              orgName: displayName,
                              username: displayUsername,
                              contactNum: displayContact,
                              description: displayDescription,
                              addresses: displayAddresses,
                              status: userData.status,
                              isOpen: _isOpen,
                              profileImageUrl: displayImageUrl,
                              isEditing: _isEditing,
                              onEditPressed: () {
                                if (_isEditing) {
                                  _saveOrgProfile();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              onImageTap: _pickImage,
                              onImageViewTap: () =>
                                  _viewProfileImage(displayImageUrl),
                              onAddAddress: _addAddress,
                              onRemoveAddress: _removeAddress,
                              nameController:
                                  _isEditing ? _nameController : null,
                              usernameController:
                                  _isEditing ? _usernameController : null,
                              descriptionController: _isEditing
                                  ? _descriptionController
                                  : null,
                              contactController:
                                  _isEditing ? _contactNumController : null,
                              addressControllers: _isEditing
                                  ? _addressControllers
                                  : null,
                              onIsOpenChanged: (value) =>
                                  setState(() => _isOpen = value),
                            ),
                            const SizedBox(height: 24),
                            if (_isEditing) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () async {
                                              await _cancelEdit();
                                            },
                                      icon: const Icon(Icons.cancel, size: 22),
                                      label: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        foregroundColor: colorScheme.primary,
                                        side: BorderSide(color: colorScheme.primary, width: 2),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isSaving ? null : _saveOrgProfile,
                                      icon: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save,
                                              size: 22, color: Colors.white),
                                      label: Text(
                                        _isSaving ? 'Saving...' : 'Save Changes',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (!_isEditing) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => context.read<MyAuthProvider>().signOut(),
                                  icon: const Icon(Icons.logout, size: 22, color: Colors.white),
                                  label: const Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: colorScheme.error,
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
        ),
      );
  }
}
