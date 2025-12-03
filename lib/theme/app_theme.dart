import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive Design System for Smart Navigation System
/// Follows Material Design 3 principles with accessibility in mind

class AppTheme {
  // Color Palette - WCAG 2.1 AA compliant
  static const Color primaryColor = Color(0xFF2E7D32); // Green 800
  static const Color primaryLight = Color(0xFF4CAF50); // Green 500
  static const Color primaryDark = Color(0xFF1B5E20); // Green 900
  static const Color secondaryColor = Color(0xFF1976D2); // Blue 700
  static const Color accentColor = Color(0xFFFF9800); // Orange 500
  
  // Semantic Colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Text Colors (WCAG AA compliant)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Border and Divider Colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Spacing System (8px grid)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // Elevation/Shadow
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
  
  // Touch Target Sizes (minimum 44x44 for accessibility)
  static const double touchTargetMin = 44.0;
  static const double buttonHeight = 48.0;
  static const double iconButtonSize = 48.0;
  
  // Typography Scale
  static const String fontFamily = 'Roboto';
  
  static TextTheme get textTheme => TextTheme(
    // Display
    displayLarge: const TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: textPrimary,
      height: 1.12,
    ),
    displayMedium: const TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.16,
    ),
    displaySmall: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.22,
    ),
    // Headline
    headlineLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.25,
    ),
    headlineMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.29,
    ),
    headlineSmall: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.33,
    ),
    // Title
    titleLarge: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: textPrimary,
      height: 1.27,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: textPrimary,
      height: 1.5,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: textPrimary,
      height: 1.43,
    ),
    // Body
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: textPrimary,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: textPrimary,
      height: 1.43,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: textSecondary,
      height: 1.33,
    ),
    // Label
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: textPrimary,
      height: 1.43,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: textPrimary,
      height: 1.33,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: textSecondary,
      height: 1.45,
    ),
  );
  
  // App Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: textOnPrimary,
        onSecondary: textOnPrimary,
        onError: textOnPrimary,
        onSurface: textPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: textTheme,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: false,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(
          color: textOnPrimary,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusS),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: textDisabled),
        errorStyle: textTheme.bodySmall?.copyWith(color: errorColor),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation2,
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          minimumSize: const Size(touchTargetMin, touchTargetMin),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation4,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderColor,
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Visual Density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  // Animation Durations
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // Page Transitions
  static PageTransitionsTheme get pageTransitionsTheme {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}

