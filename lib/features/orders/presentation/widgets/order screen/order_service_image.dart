// lib/features/orders/presentation/widgets/order_screen/order_service_image.dart
//
// Small avatar/thumbnail for a service inside an order card.

import 'package:flutter/material.dart';
import '../../../../../core/widgets/app_network_image.dart';

class OrderServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  final double size;
  final double radius;

  const OrderServiceImage({
    super.key,
    this.imageUrl,
    required this.isDark,
    this.size = 54,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      url: imageUrl,
      width: size,
      height: size,
      radius: radius,
      isDark: isDark,
      fallbackIcon: Icons.local_laundry_service,
    );
  }
}
