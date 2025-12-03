import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  UserModel? _userProfile;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isLoadingProfile = false;
        });
        return;
      }

      final profile = await _firebaseService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.displayName;
          _phoneController.text = profile.phoneNumber ?? '';
          _isLoadingProfile = false;
        });
      } else {
        // If profile doesn't exist, use auth user data
        setState(() {
          _nameController.text = user.displayName ?? 'User';
          _phoneController.text = user.phoneNumber ?? '';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _firebaseService.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final displayName = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim();

      // Update Firebase Auth display name
      await user.updateDisplayName(displayName);
      await user.reload();

      // Update or create user profile in Firestore
      if (_userProfile != null) {
        // Update existing profile
        final updatedProfile = _userProfile!.copyWith(
          displayName: displayName,
          phoneNumber: phoneNumber,
        );
        await _firebaseService.updateUserProfile(updatedProfile);
      } else {
        // Create new profile if it doesn't exist
        final newProfile = UserModel(
          userId: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: UserPreferences.defaultPreferences(),
        );
        await _firebaseService.updateUserProfile(newProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update profile: ${e.toString()}';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _firebaseService.currentUser;
    final email = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(color: AppTheme.errorColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                    ],

                    // Profile Picture Section
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textOnPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'Profile Picture',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile picture upload coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Change Photo'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Display Name Field
                    InputField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      type: InputFieldType.text,
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      validator: InputValidators.required('Full Name'),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Email Field (Read-only)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.borderColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  email,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.lock_outline,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'Email cannot be changed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Phone Number Field
                    InputField(
                      label: 'Phone Number (Optional)',
                      hintText: 'Enter your phone number',
                      type: InputFieldType.phone,
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                      validator: InputValidators.phone(),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      onPressed: _isLoading ? null : _saveProfile,
                      isLoading: _isLoading,
                      icon: Icons.save,
                      height: 56,
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Cancel Button
                    CustomButton(
                      text: 'Cancel',
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      variant: ButtonVariant.outline,
                      height: 56,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

