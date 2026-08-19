// lib/features/orders/presentation/widgets/place_order/po_store_card.dart
//
// Selectable store card for step 2 of the place-order wizard.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_selectable_card.dart';
import '../../../../store/domain/entities/store_entity.dart';

class PoStoreCard extends StatelessWidget {
  final StoreEntity store;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const PoStoreCard({
    super.key,
    required this.store,
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
            imageUrl: store.logoUrl,
            fallbackIcon: Iconsax.shop,
            selected: selected,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  store.address,
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${store.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.alexandria(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
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
