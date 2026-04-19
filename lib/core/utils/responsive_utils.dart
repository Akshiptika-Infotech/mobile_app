import 'package:flutter/material.dart';

/// Responsive utility class for consistent sizing across all screens
class ResponsiveUtils {
  ResponsiveUtils._();

  /// Get responsive dashboard header height based on screen size
  static double getHeaderHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 600 ? 120.0 : 160.0;
  }

  /// Check if device is considered a small phone (< 400px width)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 400;
  }

  /// Check if device is considered a small screen (< 600px height)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).height < 600;
  }

  /// Get responsive logo size
  static double getLogoSize(BuildContext context) {
    return isSmallScreen(context) ? 72.0 : 96.0;
  }

  /// Get responsive padding for small screens
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 400;
    return EdgeInsets.symmetric(
      horizontal: isSmall ? 12 : 16,
      vertical: isSmall ? 12 : 16,
    );
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double defaultSize,
    required double smallSize,
  }) {
    return isSmallScreen(context) ? smallSize : defaultSize;
  }

  /// Calculate responsive grid column count
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 2;
    if (width < 600) return 2;
    return 3;
  }

  /// Get responsive header height for list screens
  static double getListHeaderHeight(BuildContext context) {
    return isSmallScreen(context) ? 100.0 : 140.0;
  }
}
