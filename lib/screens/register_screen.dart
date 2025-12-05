import 'package:flutter/material.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';
import '../services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseService = FirebaseService();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _firebaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Registration timed out. Please check your connection and try again.');
        },
      );

      if (user != null && mounted) {
        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          _showError('Registration failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to start shopping smarter',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  InputField(
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    type: InputFieldType.text,
                    prefixIcon: Icons.person_outline,
                    controller: _nameController,
                    validator: InputValidators.required('Full Name'),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  InputField(
                    label: 'Email',
                    hintText: 'Enter your email',
                    type: InputFieldType.email,
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    validator: InputValidators.email(),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  InputField(
                    label: 'Password',
                    hintText: 'Create a password',
                    type: InputFieldType.password,
                    prefixIcon: Icons.lock_outline,
                    controller: _passwordController,
                    validator: InputValidators.password(),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  InputField(
                    label: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    type: InputFieldType.password,
                    prefixIcon: Icons.lock_outline,
                    controller: _confirmPasswordController,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  CustomButton(
                    text: 'Create Account',
                    onPressed: _handleRegister,
                    isLoading: _isLoading,
                    icon: Icons.person_add,
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Sign In'),
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
