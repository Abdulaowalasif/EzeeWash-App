// lib/features/orders/presentation/widgets/track_order_details_card.dart
//
// The "Pickup Details" / "Delivery Details" card shown in every phase panel.
// Automatically switches label and data based on the current order phase.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/order_shared/app_info_tile.dart';
import '../../../../core/widgets/order_shared/app_surface_card.dart';
import '../../domain/entities/order_entity.dart';
import '../screens/track_order_screen.dart' show OrderPhase;

class TrackOrderDetailsCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final OrderPhase phase;

  const TrackOrderDetailsCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isDeliveryTarget = phase.index >= OrderPhase.atStore.index;

    final title = isDeliveryTarget ? 'Delivery Details' : 'Pickup Details';
    final targetAddress = isDeliveryTarget
        ? (order.deliveryAddress ?? order.pickupAddress)
        : order.pickupAddress;
    final dateLabel =
        isDeliveryTarget ? 'Estimated Delivery' : 'Scheduled Pickup';
    final dateValue =
        isDeliveryTarget ? order.deliveryDate : order.pickupDate;
    final timeValue =
        isDeliveryTarget ? order.deliveryTime : order.pickupTime;
    final iconColor =
        isDeliveryTarget ? AppColors.success : AppColors.primary;

    return AppSurfaceCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          AppInfoTile(
            icon: Icons.location_on_rounded,
            color: iconColor,
            title: 'Address',
            sub: targetAddress,
            isDark: isDark,
          ),
          AppInfoTile(
            icon: Iconsax.timer_1,
            color: AppColors.warning,
            title: dateLabel,
            sub: dateValue != null
                ? '${dateValue.day}/${dateValue.month}/${dateValue.year}'
                    '${timeValue != null ? " at $timeValue" : ""}'
                : 'To be updated',
            isDark: isDark,
          ),
          AppInfoTile(
            icon: Iconsax.shop,
            color: const Color(0xFF8B5CF6),
            title: 'Processing Store',
            sub: order.storeName,
            isDark: isDark,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
