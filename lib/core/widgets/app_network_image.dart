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

  String _optimizeUrl(String original, BuildContext context) {
    // Only optimize if it's a standard Supabase storage public object URL
    if (!original.contains('/storage/v1/object/public/')) return original;

    // Convert the object endpoint to the render endpoint for image transformations
    var optimized = original.replaceAll(
      '/storage/v1/object/public/', 
      '/storage/v1/render/image/public/',
    );

    // Append resolution constraints based on requested UI dimensions
    final pr = MediaQuery.devicePixelRatioOf(context);
    final w = width != double.infinity ? (width * pr).toInt() : 800;
    final h = height != double.infinity ? (height * pr).toInt() : 800;
    
    // Add query parameters for server-side resizing and optimization
    final separator = optimized.contains('?') ? '&' : '?';
    return '$optimized${separator}width=$w&height=$h&resize=cover&quality=80&format=webp';
  }

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = url != null && url!.isNotEmpty ? _optimizeUrl(url!, context) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: optimizedUrl != null
            ? CachedNetworkImage(
                imageUrl: optimizedUrl,
                fit: fit,
                memCacheWidth: width != double.infinity
                    ? (width * MediaQuery.devicePixelRatioOf(context)).toInt()
                    : null,
                memCacheHeight: height != double.infinity
                    ? (height * MediaQuery.devicePixelRatioOf(context)).toInt()
                    : null,
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
