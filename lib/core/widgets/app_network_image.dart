// lib/core/widgets/app_network_image.dart
//
// Reusable cached network image with built-in shimmer placeholder and
// gradient error fallback. Replaces inline CachedNetworkImage blocks
// scattered across home, service, order, and place-order screens.
//
// Usage:
//   AppNetworkImage(url: s.imageUrl, width: 60, height: 60)
//   AppNetworkImage(url: url, width: 54, height: 54, radius: 16, fallbackIcon: Icons.local_laundry_service)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_color.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final bool isDark;

  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 16,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.local_laundry_service,
    this.fallbackIconSize = 28,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: url!,
          fit: fit,
          placeholder: (_, _) => _shimmer(),
          errorWidget: (_, _, _) => _fallback(),
        )
            : _fallback(),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
    highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
    child: Container(color: Colors.white),
  );

  Widget _fallback() => Container(
    decoration: const BoxDecoration(gradient: AppColors.gradient),
    child: Icon(fallbackIcon, color: Colors.white, size: fallbackIconSize),
  );
}