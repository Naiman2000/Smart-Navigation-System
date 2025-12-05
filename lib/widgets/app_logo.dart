import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable logo widget for the Grocery Navigator app
/// 
/// The logo combines navigation (compass) and shopping (cart) elements
/// with the app's color scheme (green primary, blue secondary)
class AppLogo extends StatelessWidget {
  /// The size of the logo
  final double size;
  
  /// The variant of the logo to use
  /// - 'full': Full detailed logo (512x512)
  /// - 'icon': Medium icon version (256x256)
  /// - 'simple': Simple compact version (128x128)
  final String variant;
  
  /// Optional color filter to apply to the logo
  final Color? color;
  
  /// Whether to show a background circle
  final bool showBackground;

  const AppLogo({
    super.key,
    this.size = 120.0,
    this.variant = 'icon',
    this.color,
    this.showBackground = false,
  });

  String get _assetPath {
    switch (variant) {
      case 'full':
        return 'assets/images/logo/app_logo.svg';
      case 'simple':
        return 'assets/images/logo/app_logo_simple.svg';
      case 'icon':
      default:
        return 'assets/images/logo/app_logo_icon.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget logo = SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      semanticsLabel: 'Grocery Navigator Logo',
    );

    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: logo,
      );
    }

    return logo;
  }
}


