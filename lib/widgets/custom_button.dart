import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  danger,
  outline,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on variant
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        borderColor = null;
        break;
      case ButtonVariant.secondary:
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.black87;
        borderColor = null;
        break;
      case ButtonVariant.danger:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        borderColor = null;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = Colors.green;
        borderColor = Colors.green;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
          disabledForegroundColor: textColor.withOpacity(0.6),
          elevation: variant == ButtonVariant.outline ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 2)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}




