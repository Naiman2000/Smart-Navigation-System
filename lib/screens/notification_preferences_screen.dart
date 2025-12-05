import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _errorMessage;
  
  // Notification preferences
  bool _notificationsEnabled = true;
  bool _shoppingListReminders = true;
  bool _storeUpdates = true;
  bool _promotionalOffers = false;
  bool _orderUpdates = true;

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure navigation is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserPreferences();
      }
    });
  }

  Future<void> _loadUserPreferences() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User not logged in';
            _isLoadingProfile = false;
          });
        }
        return;
      }

      final profile = await _firebaseService.getUserProfile(user.uid)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out. Please check your connection.');
            },
          );
      if (mounted) {
        if (profile != null) {
          setState(() {
            _notificationsEnabled = profile.preferences.notifications;
            // For now, use the main notification setting for all sub-settings
            // In the future, these could be stored separately in preferences
            _shoppingListReminders = profile.preferences.notifications;
            _storeUpdates = profile.preferences.notifications;
            _promotionalOffers = false; // Default to false
            _orderUpdates = profile.preferences.notifications;
            _isLoadingProfile = false;
          });
        } else {
          // Use defaults if profile doesn't exist
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load preferences: ${e.toString()}';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
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
      // Get current profile or create default
      UserModel? profile = await _firebaseService.getUserProfile(user.uid);
      
      if (profile == null) {
        // Create new profile with preferences
        profile = UserModel(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          phoneNumber: user.phoneNumber,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: UserPreferences(
            notifications: _notificationsEnabled,
            language: 'en',
            theme: 'light',
          ),
        );
      } else {
        // Update existing profile preferences
        profile = profile.copyWith(
          preferences: profile.preferences.copyWith(
            notifications: _notificationsEnabled,
          ),
        );
      }

      await _firebaseService.updateUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved successfully!'),
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
          _errorMessage = 'Failed to save preferences: ${e.toString()}';
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  // Info Card
                  Card(
                    elevation: AppTheme.elevation2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.infoColor,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Text(
                              'Manage how you receive notifications from Grocery Navigator',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Main Notification Toggle
                  Card(
                    elevation: AppTheme.elevation2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Enable Notifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Turn on/off all notifications',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                          // When main toggle is off, turn off all sub-settings
                          if (!value) {
                            _shoppingListReminders = false;
                            _storeUpdates = false;
                            _promotionalOffers = false;
                            _orderUpdates = false;
                          } else {
                            // When main toggle is on, turn on default settings
                            _shoppingListReminders = true;
                            _storeUpdates = true;
                            _orderUpdates = true;
                          }
                        });
                      },
                      activeThumbColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingL),

                  // Notification Types Section
                  Text(
                    'Notification Types',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Shopping List Reminders
                  Card(
                    elevation: AppTheme.elevation1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.shopping_basket,
                            color: AppTheme.secondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Shopping List Reminders',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Get reminded about your grocery lists',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _notificationsEnabled && _shoppingListReminders,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _shoppingListReminders = value;
                              });
                            }
                          : null,
                      activeThumbColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  // Store Updates
                  Card(
                    elevation: AppTheme.elevation1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.store,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Store Updates',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Notifications about store changes and new features',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _notificationsEnabled && _storeUpdates,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _storeUpdates = value;
                              });
                            }
                          : null,
                      activeThumbColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  // Order Updates
                  Card(
                    elevation: AppTheme.elevation1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: AppTheme.infoColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Order Updates',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Updates about your shopping orders',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _notificationsEnabled && _orderUpdates,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _orderUpdates = value;
                              });
                            }
                          : null,
                      activeThumbColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  // Promotional Offers
                  Card(
                    elevation: AppTheme.elevation1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: SwitchListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: AppTheme.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'Promotional Offers',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Special deals and promotional notifications',
                        style: theme.textTheme.bodySmall,
                      ),
                      value: _notificationsEnabled && _promotionalOffers,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() {
                                _promotionalOffers = value;
                              });
                            }
                          : null,
                      activeThumbColor: AppTheme.primaryColor,
                      activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.textOnPrimary,
                        minimumSize: const Size(double.infinity, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                          vertical: AppTheme.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.textOnPrimary,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save, size: 20),
                                const SizedBox(width: AppTheme.spacingS),
                                Text(
                                  'Save Preferences',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

