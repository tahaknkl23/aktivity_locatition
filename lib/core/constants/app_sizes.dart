import 'package:flutter/material.dart';

class AppDimensions {
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Padding & Margins
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Avatar Sizes
  static const double avatarS = 32.0;
  static const double avatarM = 48.0;
  static const double avatarL = 64.0;
  static const double avatarXL = 96.0;
}

class AppSizes {
  final double width;
  final double height;

  const AppSizes({
    required this.width,
    required this.height,
  });

  factory AppSizes.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppSizes(width: size.width, height: size.height);
  }

  // Base measurements
  double get padding => width * 0.04; // ~16px on 400px width
  double get formSpacing => height * 0.03; // ~24px on 800px height

  // Text sizes - responsive
  double get smallText => width * 0.035; // ~14px
  double get textSize => width * 0.04; // ~16px
  double get textSmall => width * 0.032; // ~13px
  double get mediumText => width * 0.045; // ~18px
  double get largeText => width * 0.055; // ~22px
  double get titleText => width * 0.07; // ~28px
  double get headerText => width * 0.08; // ~32px

  // Button sizes
  double get buttonHeight => height * 0.06; // ~48px
  double get smallButtonHeight => height * 0.045; // ~36px

  // Icon sizes - responsive
  double get smallIcon => width * 0.05; // ~20px
  double get mediumIcon => width * 0.06; // ~24px
  double get largeIcon => width * 0.08; // ~32px

  // Layout helpers
  bool get isMobile => width < AppDimensions.mobileBreakpoint;
  bool get isTablet => width >= AppDimensions.mobileBreakpoint && width < AppDimensions.tabletBreakpoint;
  bool get isDesktop => width >= AppDimensions.desktopBreakpoint;

  // Safe areas for different screen sizes
  double get horizontalPadding {
    if (isMobile) return padding;
    if (isTablet) return padding * 2;
    return padding * 3;
  }

  double get verticalPadding {
    if (isMobile) return padding * 0.8;
    if (isTablet) return padding * 1.2;
    return padding * 1.5;
  }

  // Card and container sizes
  double get cardBorderRadius => isMobile ? AppDimensions.radiusM : AppDimensions.radiusL;
  double get cardPadding => isMobile ? AppDimensions.paddingM : AppDimensions.paddingL;

  // Form field sizes
  double get formFieldHeight => isMobile ? 48 : 56;
  double get formFieldBorderRadius => AppDimensions.radiusM;

  // App bar heights
  double get appBarHeight => isMobile ? 56 : 64;
  double get toolbarHeight => isMobile ? 56 : 64;

  // Bottom navigation
  double get bottomNavHeight => isMobile ? 60 : 70;

  // Spacing helpers
  double get tinySpacing => padding * 0.25; // 4px
  double get smallSpacing => padding * 0.5; // 8px
  double get mediumSpacing => padding; // 16px
  double get largeSpacing => padding * 1.5; // 24px
  double get extraLargeSpacing => padding * 2; // 32px

  // Animation durations (in milliseconds)
  int get fastAnimation => 200;
  int get normalAnimation => 300;
  int get slowAnimation => 500;
}
