// lib/features/orders/presentation/widgets/place_order/po_store_card.dart
//
// Selectable store card for step 2 of the place-order wizard.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/form/app_selectable_card.dart';
import '../../../../store/domain/entities/store_entity.dart';

class PoStoreItem {
  final String id, name, address, distance;
  final String? logoUrl;

  // ── Dynamic booking fields (EC-26: per-store hours) ──
  final int openHour;
  final int closeHour;
  final int slotIntervalHours;
  final int pickupBufferHours;
  final int advanceBookingDays;
  final int slotCapacity;

  const PoStoreItem({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.logoUrl,
    this.openHour = 8,
    this.closeHour = 20,
    this.slotIntervalHours = 2,
    this.pickupBufferHours = 2,
    this.advanceBookingDays = 7,
    this.slotCapacity = 100,
  });

  factory PoStoreItem.fromJson(Map<String, dynamic> j) => PoStoreItem(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String,
    distance: '${j['distance_km'] ?? '?'} km',
    logoUrl: j['logo_url'] as String?,
    openHour: j['open_hour'] as int? ?? 8,
    closeHour: j['close_hour'] as int? ?? 20,
    slotIntervalHours: j['slot_interval_hours'] as int? ?? 2,
    pickupBufferHours: j['pickup_buffer_hours'] as int? ?? 2,
    advanceBookingDays: j['advance_booking_days'] as int? ?? 7,
    slotCapacity: j['slot_capacity'] as int? ?? 100,
  );

  /// Converts this store's booking fields into a [StoreEntity]
  /// suitable for passing to all [BusinessLogicUtils] scheduling methods.
  StoreEntity toStoreEntity() => StoreEntity(
    id: id,
    name: name,
    address: address,
    distanceKm: double.tryParse(distance.replaceAll(' km', '')) ?? 0.0,
    isActive: true,
    logoUrl: logoUrl,
    openHour: openHour,
    closeHour: closeHour,
    slotCapacity: slotCapacity,
    slotIntervalHours: slotIntervalHours,
    pickupBufferHours: pickupBufferHours,
    advanceBookingDays: advanceBookingDays,
  );
}

class PoStoreCard extends StatelessWidget {
  final PoStoreItem store;
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
                  store.distance,
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