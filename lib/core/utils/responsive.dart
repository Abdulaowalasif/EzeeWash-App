// lib/core/utils/responsive.dart
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppConstants.desktopBreakpoint) return DeviceType.desktop;
    if (width >= AppConstants.mobileBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Returns [mobile] on mobile, [tablet] on tablet, [desktop] on desktop
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final type = getDeviceType(context);
    if (type == DeviceType.desktop && desktop != null) return desktop;
    if (type == DeviceType.tablet && tablet != null) return tablet;
    return mobile;
  }

  /// Grid cross-axis count
  static int gridCount(BuildContext context) =>
      value(context, mobile: 2, tablet: 3, desktop: 4);

  /// Horizontal padding
  static double horizontalPadding(BuildContext context) =>
      value(context, mobile: 20.0, tablet: 40.0, desktop: 80.0);

  /// Max content width (for centering on large screens)
  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 700.0, desktop: 1000.0);
}
