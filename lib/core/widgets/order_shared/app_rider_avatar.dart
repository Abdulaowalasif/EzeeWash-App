// lib/core/widgets/order_shared/app_rider_avatar.dart
//
// Rider avatar with an online/offline status dot badge.
// Falls back to an initial letter if no photo is available.
//
// Usage:
//   AppRiderAvatar(
//     name: 'Karim Hossain',
//     photoUrl: rider.avatarUrl,
//     isOnline: rider.isOnline,
//     size: 90,
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';
import '../app_network_image.dart';

class AppRiderAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isOnline;
  final double size;

  const AppRiderAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    required this.isOnline,
    this.size = 90,
  });

  Widget _fallback() => Container(
    color: AppColors.primary.withValues(alpha: 0.12),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'R',
      style: GoogleFonts.alexandria(
        color: AppColors.primary,
        fontSize: size * 0.36,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.24;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: photoUrl != null
              ? AppNetworkImage(
                  url: photoUrl!,
                  width: size,
                  height: size,
                  radius: size / 2, // Circular
                  fallbackIcon: Icons.motorcycle,
                )
              : _fallback(),
        ),
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? AppColors.success : Colors.grey.shade400,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        ),
      ],
    );
  }
}
