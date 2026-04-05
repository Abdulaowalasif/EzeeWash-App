// lib/core/widgets/app_shimmer_box.dart
//
// A single shimmer placeholder rectangle.  Wrap multiple instances inside
// Shimmer.fromColors when you need a shimmer group.
//
// Usage:
//   Shimmer.fromColors(
//     baseColor: ..., highlightColor: ...,
//     child: Column(children: [
//       AppShimmerBox(height: 120, radius: 18),
//       AppShimmerBox(height: 120, radius: 18),
//     ]),
//   )

import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class AppShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const AppShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Convenience: returns shimmer base/highlight colors for a given brightness.
class AppShimmerColors {
  AppShimmerColors._();

  static Color base(bool isDark) =>
      isDark ? Colors.grey[800]! : Colors.grey[300]!;

  static Color highlight(bool isDark) =>
      isDark ? Colors.grey[700]! : Colors.grey[100]!;
}