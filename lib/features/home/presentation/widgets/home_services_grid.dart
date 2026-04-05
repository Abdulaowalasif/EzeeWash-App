// lib/features/home/presentation/widgets/home_services_grid.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_shimmer_box.dart';
import '../../../../routes/routes_name.dart';
import '../../../services/presentation/bloc/service_bloc.dart';
import '../../../services/presentation/bloc/service_state.dart';

class HomeServicesGrid extends StatelessWidget {
  final bool isDark;
  final int crossAxisCount;
  final String localQuery;

  const HomeServicesGrid({
    super.key,
    required this.isDark,
    required this.crossAxisCount,
    required this.localQuery,
  });

  static const _fallbackIcons = [
    Icons.water_drop_outlined,
    Icons.dry_cleaning_outlined,
    Icons.local_fire_department_outlined,
    Icons.flash_on,
  ];

  SliverGridDelegate get _gridDelegate =>
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount > 2 ? 0.9 : 0.78,
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      buildWhen: (prev, curr) {
        if (prev is ServicesLoaded && curr is ServicesLoaded) {
          return prev.services != curr.services;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        if (state is ServicesLoading) return _ShimmerGrid(isDark: isDark, gridDelegate: _gridDelegate);

        if (state is ServicesLoaded) {
          final q = localQuery.toLowerCase().trim();
          final all = List.of(state.services)
            ..sort((a, b) => b.rating.compareTo(a.rating));

          final services = (q.isEmpty
                  ? all
                  : all.where((s) =>
                      s.title.toLowerCase().contains(q) ||
                      (s.description?.toLowerCase().contains(q) ?? false) ||
                      s.tags.any((t) => t.toLowerCase().contains(q))))
              .take(4)
              .toList();

          if (services.isEmpty && q.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No services found for "$localQuery"',
                  style: AppTextStyles.caption(isDark),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _gridDelegate,
            itemCount: services.length,
            itemBuilder: (context, i) {
              final s = services[i];
              return HomeServiceCard(
                title: s.title,
                subtitle: s.description ?? '',
                price: s.price.toStringAsFixed(0),
                rating: s.rating,
                imageUrl: s.imageUrl,
                fallbackIcon: _fallbackIcons[i % _fallbackIcons.length],
                isDark: isDark,
                onTap: () =>
                    context.push(RoutesName.placeOrdersNavigate, extra: s.id),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Shimmer placeholder grid ─────────────────────────────────────────────────

class _ShimmerGrid extends StatelessWidget {
  final bool isDark;
  final SliverGridDelegate gridDelegate;

  const _ShimmerGrid({required this.isDark, required this.gridDelegate});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppShimmerColors.base(isDark),
        highlightColor: AppShimmerColors.highlight(isDark),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: 4,
          itemBuilder: (_, __) => const AppShimmerBox(height: 160, radius: 20),
        ),
      );
}

// ─── Service card ─────────────────────────────────────────────────────────────

class HomeServiceCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final double rating;
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool isDark;
  final VoidCallback onTap;

  const HomeServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    this.imageUrl,
    required this.fallbackIcon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<HomeServiceCard> createState() => _HomeServiceCardState();
}

class _HomeServiceCardState extends State<HomeServiceCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: widget.isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CardImage(
                imageUrl: widget.imageUrl,
                fallbackIcon: widget.fallbackIcon,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 10),
              _CardTitleRow(
                title: widget.title,
                rating: widget.rating,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: AppTextStyles.tiny(widget.isDark),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('From ৳${widget.price}', style: AppTextStyles.price),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool isDark;

  const _CardImage({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: imageUrl == null ? AppColors.gradient : null,
        color: imageUrl != null
            ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppNetworkImage(
        url: imageUrl,
        width: 60,
        height: 60,
        radius: 16,
        fallbackIcon: fallbackIcon,
        fallbackIconSize: 26,
        isDark: isDark,
      ),
    );
  }
}

class _CardTitleRow extends StatelessWidget {
  final String title;
  final double rating;
  final bool isDark;

  const _CardTitleRow({
    required this.title,
    required this.rating,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.gridTitle(isDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating > 0) ...[
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
          Text(rating.toStringAsFixed(1), style: AppTextStyles.rating),
        ],
      ],
    );
  }
}
