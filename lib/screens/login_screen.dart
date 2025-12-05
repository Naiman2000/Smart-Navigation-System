import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';
import '../services/firebase_service.dart';
import '../services/credentials_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _credentialsService = CredentialsService();

  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  /// Load saved credentials if "Remember Me" was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      final rememberMe = await _credentialsService.getSaveCredentialsPref();
      if (rememberMe) {
        final credentials = await _credentialsService.loadCredentials();
        if (credentials != null && mounted) {
          setState(() {
            _emailController.text = credentials['email'] ?? '';
            _passwordController.text = credentials['password'] ?? '';
            _rememberMe = true;
          });
        }
      }
    } catch (e) {
      // Silently fail - not critical if we can't load credentials
      debugPrint('Failed to load credentials: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await _firebaseService.signIn(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Login timed out. Please check your connection and try again.');
        },
      );

      if (user != null) {
        // Handle "Remember Me" preference
        if (_rememberMe) {
          await _credentialsService.saveCredentials(
            email: email,
            password: password,
          );
          await _credentialsService.setSaveCredentialsPref(true);
        } else {
          // Clear credentials if "Remember Me" is unchecked
          await _credentialsService.clearCredentials();
        }

        if (mounted) {
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          _showError('Login failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        // Clean up error message
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.textOnPrimary),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.textOnPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingM),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    // Show dialog to enter email
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
        builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primaryColor),
            SizedBox(width: AppTheme.spacingS),
            Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _sendPasswordResetEmail(emailController.text.trim());
    }

    emailController.dispose();
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.resetPassword(email)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Password reset request timed out. Please check your connection and try again.');
            },
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                SizedBox(width: AppTheme.spacingS),
                Text('Email Sent'),
              ],
            ),
            content: Text(
              'A password reset link has been sent to:\n$email\n\nPlease check your inbox and follow the instructions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        _showError(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon (removed Hero to avoid duplicate tag issues)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Title
                  Text(
                    'Grocery Navigator',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Your Smart Grocery Shopping Assistant',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Email Field
                  InputField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    type: InputFieldType.email,
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    validator: InputValidators.email(),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Password Field
                  InputField(
                    label: 'Password',
                    hintText: 'Enter your password',
                    type: InputFieldType.password,
                    prefixIcon: Icons.lock_outline,
                    controller: _passwordController,
                    validator: InputValidators.required('Password'),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Remember Me Checkbox
                  Semantics(
                    label: 'Remember me checkbox',
                    child: Row(
                      children: [
                        SizedBox(
                          height: AppTheme.touchTargetMin,
                          width: AppTheme.touchTargetMin,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              'Remember me',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Login Button
                  CustomButton(
                    text: 'Login',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    icon: Icons.login,
                    semanticLabel: 'Login button',
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
