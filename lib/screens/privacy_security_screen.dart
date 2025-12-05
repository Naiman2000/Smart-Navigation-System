import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isChangingPassword = false;
  bool _showPasswordSection = false;
  String? _errorMessage;
  String? _successMessage;

  // Privacy settings
  bool _shareAnalytics = true;
  bool _allowPersonalization = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in';
          _isChangingPassword = false;
        });
        return;
      }

      // Re-authenticate user before changing password
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Re-authenticate with current password with timeout
      final credential = await _firebaseService.reauthenticateUser(
        email: email,
        password: _currentPasswordController.text,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Re-authentication timed out. Please check your connection.');
        },
      );

      // Update password with timeout
      final authenticatedUser = credential.user;
      if (authenticatedUser == null) {
        throw Exception('Re-authentication failed');
      }
      await authenticatedUser.updatePassword(newPassword)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Password update timed out. Please check your connection.');
            },
          );

      if (mounted) {
        setState(() {
          _isChangingPassword = false;
          _successMessage = 'Password changed successfully!';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _showPasswordSection = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to change password';
        if (e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential')) {
          errorMessage = 'Current password is incorrect';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'New password is too weak';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isChangingPassword = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorColor),
            SizedBox(width: AppTheme.spacingS),
            Text('Delete Account'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, including shopping lists, will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deletion is not yet implemented. Please contact support.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _firebaseService.currentUser;
    final email = user?.email ?? 'No email';
    final lastLogin = user?.metadata.lastSignInTime;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
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

            // Success Message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: Border.all(color: AppTheme.successColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppTheme.successColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],

            // Account Security Section
            Text(
              'Account Security',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Account Info Card
            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_circle,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          'Account Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      email,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Last Login',
                      lastLogin != null
                          ? '${lastLogin.day}/${lastLogin.month}/${lastLogin.year}'
                          : 'Unknown',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Change Password Section
            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'Change Password',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Update your account password'),
                    trailing: IconButton(
                      icon: Icon(
                        _showPasswordSection
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPasswordSection = !_showPasswordSection;
                          if (!_showPasswordSection) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            _errorMessage = null;
                            _successMessage = null;
                          }
                        });
                      },
                    ),
                  ),
                  if (_showPasswordSection) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            InputField(
                              label: 'Current Password',
                              hintText: 'Enter your current password',
                              type: InputFieldType.password,
                              prefixIcon: Icons.lock_outline,
                              controller: _currentPasswordController,
                              validator: InputValidators.required('Current Password'),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            InputField(
                              label: 'New Password',
                              hintText: 'Enter your new password',
                              type: InputFieldType.password,
                              prefixIcon: Icons.lock,
                              controller: _newPasswordController,
                              validator: InputValidators.password(),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            InputField(
                              label: 'Confirm New Password',
                              hintText: 'Re-enter your new password',
                              type: InputFieldType.password,
                              prefixIcon: Icons.lock,
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            CustomButton(
                              text: 'Change Password',
                              onPressed: _isChangingPassword ? null : _changePassword,
                              isLoading: _isChangingPassword,
                              icon: Icons.lock_reset,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Privacy Settings Section
            Text(
              'Privacy Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: AppTheme.secondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Share Analytics',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'Help improve the app by sharing anonymous usage data',
                    ),
                    value: _shareAnalytics,
                    onChanged: (value) {
                      setState(() {
                        _shareAnalytics = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryColor,
                    activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Personalization',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    subtitle: const Text(
                      'Allow personalized recommendations and content',
                    ),
                    value: _allowPersonalization,
                    onChanged: (value) {
                      setState(() {
                        _allowPersonalization = value;
                      });
                    },
                    activeThumbColor: AppTheme.primaryColor,
                    activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Data Management Section
            Text(
              'Data Management',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            Card(
              elevation: AppTheme.elevation2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.download_outlined,
                      color: AppTheme.infoColor,
                    ),
                    title: Text(
                      'Export Data',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: const Text('Download your account data'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data export feature coming soon'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorColor,
                    ),
                    title: Text(
                      'Delete Account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                    subtitle: const Text('Permanently delete your account and data'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

