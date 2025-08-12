import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ksrtc_users/models/user_model.dart';
import 'package:ksrtc_users/services/profile_service.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final Client client;

  const ProfileScreen({super.key, required this.client});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileService _profileService;
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  // For password change
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isChangingPassword = false;

  // For profile image
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(widget.client);
    _loadUserProfile();

    // Initialize controllers
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Load user profile from service
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _profileService.getCurrentUser();
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _phoneController.text = user.phone;
        _addressController.text = user.address ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load profile: ${e.toString()}');
    }
  }

  // Save user profile
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update user model with form data
      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );

      // Upload profile image if selected
      if (_selectedImage != null) {
        final imageUrl = await _profileService.uploadProfileImage(
          _selectedImage!.path,
          _user!.id,
        );
        updatedUser.profileImageUrl = imageUrl;
      }

      // Save to backend
      final savedUser = await _profileService.updateUserProfile(updatedUser);

      setState(() {
        _user = savedUser;
        _isEditing = false;
        _isSaving = false;
        _selectedImage = null;
      });

      _showSuccessSnackBar('Profile updated successfully');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Failed to update profile: ${e.toString()}');
    }
  }

  // Change password
  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      setState(() {
        _isSaving = false;
        _isChangingPassword = false;
      });

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSuccessSnackBar('Password changed successfully');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorSnackBar('Failed to change password: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> _logout() async {
    try {
      await _profileService.logout();
      if (!mounted) return;

      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showErrorSnackBar('Failed to logout: ${e.toString()}');
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  // Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentGreen),
    );
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      await _logout();
    }
  }

  // Show password change dialog
  void _showChangePasswordDialog() {
    setState(() {
      _isChangingPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveProfile,
            ),
          if (_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _user!.name;
                  _phoneController.text = _user!.phone;
                  _addressController.text = _user!.address ?? '';
                  _selectedImage = null;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            _isChangingPassword
                ? _buildChangePasswordForm()
                : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryYellow.withOpacity(0.3),
                  backgroundImage:
                      _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _user?.profileImageUrl != null
                          ? NetworkImage(_user!.profileImageUrl!)
                          : null,
                  child:
                      _user?.profileImageUrl == null && _selectedImage == null
                          ? const Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryYellow,
                          )
                          : null,
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryDark,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email field (read-only)
          TextFormField(
            initialValue: _user?.email,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Address field
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            enabled: _isEditing,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Action buttons
          if (!_isEditing)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock),
                  label: const Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _currentPasswordController,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            decoration: const InputDecoration(
              labelText: 'New Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child:
                _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Password'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _isChangingPassword = false;
                _currentPasswordController.clear();
                _newPasswordController.clear();
                _confirmPasswordController.clear();
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
