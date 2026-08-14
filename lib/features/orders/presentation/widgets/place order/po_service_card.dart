// lib/features/orders/presentation/widgets/place_order/po_service_card.dart
//
// Selectable service card for step 1 of the place-order wizard.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_selectable_card.dart';
import '../../../../services/domain/entities/service_entity.dart';

class PoServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const PoServiceCard({
    super.key,
    required this.service,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSelectableCard(
      selected: selected,
      isDark: isDark,
      onTap: onTap,
      child: Row(
        children: [
          AppItemThumbnail(
            imageUrl: service.imageUrl,
            fallbackIcon: Iconsax.drop,
            selected: selected,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                if (service.description?.isNotEmpty ?? false)
                  Text(
                    service.description!,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                    maxLines: 1,
                  ),
                const SizedBox(height: 10),
                Text(
                  '৳${service.price.toStringAsFixed(0)}',
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (selected) const AppSelectedBadge(),
        ],
      ),
    );
  }
}
