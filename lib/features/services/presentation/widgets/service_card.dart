// lib/features/services/presentation/widgets/service_card.dart
//
// Refactored: all inline GoogleFonts.alexandria calls replaced with
// AppTextStyles. All repeated container/decoration patterns use AppCard
// for the outer shell and AppIconBox where applicable.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/service_entity.dart';
import 'service_review_sheet.dart';

class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;

  const ServiceCard(
      {super.key, required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // AppCard handles surface color, border, shadow — no duplication.
    return AppCard(
      isDark: isDark,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceHeroImage(imageUrl: service.imageUrl, isDark: isDark),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceHeaderRow(service: service, isDark: isDark),
                const SizedBox(height: 12),
                _ServiceTags(tags: service.tags, isDark: isDark),
                const SizedBox(height: 16),
                _ServiceActions(service: service, isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero image ───────────────────────────────────────────────────────────────

class _ServiceHeroImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _ServiceHeroImage({required this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: imageUrl != null
            ? AppNetworkImage(
          url: imageUrl,
          width: double.infinity,
          height: 140,
          radius: 0,
          isDark: isDark,
          fallbackIcon: Icons.local_laundry_service_rounded,
          fallbackIconSize: 56,
        )
            : _ImageFallback(isDark: isDark),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final bool isDark;
  const _ImageFallback({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    color: isDark
        ? AppColors.primary.withOpacity(0.15)
        : AppColors.primary.withOpacity(0.08),
    child: Center(
      child: Icon(
        Icons.local_laundry_service_rounded,
        size: 56,
        color: AppColors.primary.withOpacity(0.4),
      ),
    ),
  );
}

// ─── Title + price row ────────────────────────────────────────────────────────

class _ServiceHeaderRow extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;

  const _ServiceHeaderRow(
      {required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.title,
                style:
                AppTextStyles.heading(isDark).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                service.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle(isDark),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '৳${service.price.toStringAsFixed(0)}',
              style: AppTextStyles.priceLarge,
            ),
            if (service.duration != null)
              Text(service.duration!,
                  style: AppTextStyles.caption(isDark)),
          ],
        ),
      ],
    );
  }
}

// ─── Tags ─────────────────────────────────────────────────────────────────────

class _ServiceTags extends StatelessWidget {
  final List<String> tags;
  final bool isDark;

  const _ServiceTags({required this.tags, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map((t) => _TagChip(tag: t, isDark: isDark))
          .toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final bool isDark;

  const _TagChip({required this.tag, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isDark
          ? AppColors.primary.withOpacity(0.2)
          : AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      tag,
      style: AppTextStyles.captionMedium(isDark).copyWith(
        color:
        isDark ? Colors.blue.shade300 : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ─── Reviews + Book Now buttons ───────────────────────────────────────────────

class _ServiceActions extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;

  const _ServiceActions(
      {required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Reviews (outline) ───────────────────────────────────
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Iconsax.star,
                size: 16, color: AppColors.primary),
            onPressed: () =>
                ServiceReviewSheet.show(context, service, isDark),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            label:
            Text('Reviews', style: AppTextStyles.buttonOutline),
          ),
        ),
        const SizedBox(width: 12),

        // ── Book Now (gradient) ─────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.calendar_tick,
                  color: Colors.white, size: 16),
              onPressed: () => context.push(
                  RoutesName.placeOrdersNavigate,
                  extra: service.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                const EdgeInsets.symmetric(vertical: 12),
              ),
              label:
              Text('Book Now', style: AppTextStyles.buttonSmall),
            ),
          ),
        ),
      ],
    );
  }
}