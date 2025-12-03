import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum InputFieldType {
  text,
  email,
  password,
  phone,
  number,
  multiline,
}

class InputField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final InputFieldType type;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const InputField({
    super.key,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.type = InputFieldType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _obscureText = true;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    setState(() {
      _showClearButton = widget.controller?.text.isNotEmpty ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: widget.label ?? widget.hintText,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
          TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            maxLines: widget.type == InputFieldType.multiline ? null : widget.maxLines,
            maxLength: widget.maxLength,
            obscureText: widget.type == InputFieldType.password && _obscureText,
            keyboardType: _getKeyboardType(),
            textInputAction: widget.textInputAction ?? _getTextInputAction(),
            validator: widget.validator,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDisabled,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: AppTheme.primaryColor,
                      size: 20,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              filled: true,
              fillColor: widget.enabled
                  ? AppTheme.surfaceColor
                  : AppTheme.borderColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                borderSide: const BorderSide(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingM,
              ),
              counterText: '', // Hide character counter
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.type == InputFieldType.password) {
      return Semantics(
        label: _obscureText ? 'Show password' : 'Hide password',
        button: true,
        child: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          tooltip: _obscureText ? 'Show password' : 'Hide password',
        ),
      );
    }

    if (_showClearButton && widget.enabled) {
      return Semantics(
        label: 'Clear input',
        button: true,
        child: IconButton(
          icon: const Icon(
            Icons.clear,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: () {
            widget.controller?.clear();
            widget.onChanged?.call('');
          },
          tooltip: 'Clear',
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return Icon(
        widget.suffixIcon,
        color: AppTheme.textSecondary,
        size: 20,
      );
    }

    return null;
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case InputFieldType.email:
        return TextInputType.emailAddress;
      case InputFieldType.phone:
        return TextInputType.phone;
      case InputFieldType.number:
        return TextInputType.number;
      case InputFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  TextInputAction _getTextInputAction() {
    if (widget.type == InputFieldType.multiline) {
      return TextInputAction.newline;
    }
    return TextInputAction.next;
  }
}

// Common validators
class InputValidators {
  static String? Function(String?) required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  static String? Function(String?) email() {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Email is required';
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
      return null;
    };
  }

  static String? Function(String?) password() {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return 'Password must contain at least one lowercase letter';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }
      return null;
    };
  }

  static String? Function(String?) phone() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Optional field
      }
      final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Enter a valid phone number';
      }
      return null;
    };
  }

  static String? Function(String?) minLength(int length) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (value.length < length) {
        return 'Must be at least $length characters';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int length) {
    return (value) {
      if (value != null && value.length > length) {
        return 'Must be at most $length characters';
      }
      return null;
    };
  }

  static String? Function(String?) matchPassword(String password) {
    return (value) {
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }
}




