// lib/features/orders/presentation/widgets/place_order/po_service_card.dart
//
// Selectable service card for step 1 of the place-order wizard.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_selectable_card.dart';

class PoServiceItem {
  final String id, title, subtitle, duration, category;
  final double price;
  final String? imageUrl;

  const PoServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.category,
    this.imageUrl,
  });

  factory PoServiceItem.fromJson(Map<String, dynamic> j) => PoServiceItem(
        id: j['id'] as String,
        title: j['title'] as String,
        subtitle: j['description'] as String? ?? '',
        price: (j['price'] as num).toDouble(),
        duration: j['duration'] as String? ?? '',
        category: j['category'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
      );
}

class PoServiceCard extends StatelessWidget {
  final PoServiceItem service;
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
                if (service.subtitle.isNotEmpty)
                  Text(
                    service.subtitle,
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
