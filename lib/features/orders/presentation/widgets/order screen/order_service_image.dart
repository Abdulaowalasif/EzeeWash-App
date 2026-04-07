// lib/features/orders/presentation/widgets/order_screen/order_service_image.dart
//
// Small avatar/thumbnail for a service inside an order card.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_color.dart';

class OrderServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const OrderServiceImage({
    super.key,
    this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        gradient: imageUrl == null ? AppColors.gradient : null,
        color: imageUrl != null
            ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor:
                      isDark ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, _, _) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_laundry_service,
                      color: Colors.white, size: 28),
                ),
              )
            : const Icon(Icons.local_laundry_service,
                color: Colors.white, size: 28),
      ),
    );
  }
}
