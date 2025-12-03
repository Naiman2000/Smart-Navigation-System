import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
  final String? semanticLabel;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppTheme.buttonHeight,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors based on variant using theme
    Color backgroundColor;
    Color textColor;
    Color? borderColor;
    double elevation;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = AppTheme.textOnPrimary;
        borderColor = null;
        elevation = AppTheme.elevation2;
        break;
      case ButtonVariant.secondary:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = AppTheme.textPrimary;
        borderColor = null;
        elevation = AppTheme.elevation1;
        break;
      case ButtonVariant.danger:
        backgroundColor = AppTheme.errorColor;
        textColor = AppTheme.textOnPrimary;
        borderColor = null;
        elevation = AppTheme.elevation2;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        elevation = AppTheme.elevation0;
        break;
    }

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        width: width,
        child: AnimatedContainer(
          duration: AppTheme.animationShort,
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: width ?? double.infinity,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: textColor,
              disabledBackgroundColor: backgroundColor.withOpacity(0.6),
              disabledForegroundColor: textColor.withOpacity(0.6),
              elevation: elevation,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                side: borderColor != null
                    ? BorderSide(color: borderColor, width: 2)
                    : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
                vertical: AppTheme.spacingM,
              ),
              minimumSize: Size(width ?? double.infinity, height),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Prevents extra padding
            ),
            child: AnimatedSwitcher(
              duration: AppTheme.animationShort,
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      key: const ValueKey('content'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20),
                          const SizedBox(width: AppTheme.spacingS),
                        ],
                        Text(
                          text,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible, // Allow text to be fully visible
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




