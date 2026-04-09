// lib/features/orders/presentation/widgets/order_list/order_list_widgets.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/order_status.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_shimmer.dart';
import '../../../../../core/widgets/app_status_badge.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../routes/routes_name.dart';
import '../../../domain/entities/order_entity.dart';

// ─── OrderCard ────────────────────────────────────────────────────────────────

class OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isHistory;
  final bool isDark;
  final VoidCallback? onPress;

  const OrderCard({
    super.key,
    required this.order,
    required this.isHistory,
    required this.isDark,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final displayStatus = OrderStatus.getDisplayStatus(order.status);
    final statusColor = OrderStatus.getColor(displayStatus);
    final progress =
    OrderStatus.getProgress(order.status).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onPress,
      child: AppCard(
        isDark: isDark,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: order.serviceImageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: order.serviceImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                            Iconsax.drop,
                            color: Colors.white,
                            size: 24),
                      ),
                    )
                        : const Icon(Iconsax.drop,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.serviceName,
                            style: AppTextStyles.cardTitle(isDark)
                                .copyWith(fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          '#${order.orderNumber} · ${order.storeName}',
                          style: AppTextStyles.subtitle(isDark),
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(status: order.status),
                ],
              ),
            ),
            if (!isHistory)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress',
                            style: AppTextStyles.caption(isDark)),
                        Text('${(progress * 100).toInt()}%',
                            style: AppTextStyles.captionMedium(isDark)
                                .copyWith(color: statusColor)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: statusColor.withOpacity(0.15),
                        color: statusColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : AppColors.lightBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FooterInfo(
                    icon: Iconsax.calendar_1,
                    label: DateFormat('dd MMM yyyy').format(order.createdAt),
                    isDark: isDark,
                  ),
                  _FooterInfo(
                    icon: Iconsax.money,
                    label: '৳${order.totalPrice.toStringAsFixed(0)}',
                    isDark: isDark,
                    highlight: true,
                  ),
                  if (!isHistory)
                    _TrackButton(order: order, isDark: isDark)
                  else
                    _ReorderButton(order: order, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool highlight;

  const _FooterInfo({
    required this.icon,
    required this.label,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon,
          size: 14,
          color: highlight
              ? AppColors.primary
              : (isDark
              ? AppColors.darkSubtext
              : AppColors.lightSubtext)),
      const SizedBox(width: 5),
      Text(label,
          style: AppTextStyles.caption(isDark).copyWith(
            fontWeight: highlight
                ? FontWeight.bold
                : FontWeight.normal,
            color: highlight
                ? AppColors.primary
                : null,
          )),
    ],
  );
}

class _TrackButton extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _TrackButton({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(RoutesName.trackOrdersNavigate,
        extra: order.id),
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Track',
          style: AppTextStyles.buttonSmall),
    ),
  );
}

class _ReorderButton extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _ReorderButton({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(RoutesName.placeOrdersNavigate,
        extra: order),
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text('Reorder', style: AppTextStyles.buttonOutline.copyWith(fontSize: 12)),
    ),
  );
}

// ─── OrdersToggle ─────────────────────────────────────────────────────────────

class OrdersToggle extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final PageController pageController;

  const OrdersToggle({
    super.key,
    required this.showActive,
    required this.isDark,
    required this.onChanged,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // ─── Sliding Selection Background ───
          AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double page = showActive ? 0.0 : 1.0;

              // Sync with PageView scroll progress
              if (pageController.hasClients && pageController.position.haveDimensions) {
                page = pageController.page ?? page;
              }

              page = page.clamp(0.0, 1.0);
              // Calculate alignment: 0.0 page -> -1.0 alignment, 1.0 page -> 1.0 alignment
              final alignmentX = (page * 2) - 1.0;

              return Align(
                alignment: Alignment(alignmentX, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ─── Tab Labels ───
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.caption(true).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: showActive
                            ? Colors.white
                            : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
                      ),
                      child: const Text('Active Orders'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(false),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.caption(true).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: !showActive
                            ? Colors.white
                            : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
                      ),
                      child: const Text('Order History'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── OrderActiveFilterBar ─────────────────────────────────────────────────────

class OrderActiveFilterBar extends StatelessWidget {
  final List<String> chips;
  final VoidCallback onClear;

  const OrderActiveFilterBar({
    super.key,
    required this.chips,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...chips.map((c) => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(c,
                style: AppTextStyles.captionMedium(false)
                    .copyWith(color: AppColors.primary)),
          )),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded,
                      size: 12, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text('Clear',
                      style: AppTextStyles.captionMedium(false)
                          .copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OrdersShimmer ────────────────────────────────────────────────────────────

class OrdersShimmer extends StatelessWidget {
  final bool isDark;
  const OrdersShimmer({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context)),
          child: Shimmer.fromColors(
            baseColor: AppShimmerColors.base(isDark),
            highlightColor: AppShimmerColors.highlight(isDark),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: 16),
                    itemBuilder: (_, _) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── OrderEmptyState ──────────────────────────────────────────────────────────

/// Thin wrapper over [AppEmptyState] kept for call-site backwards compatibility.
class OrderEmptyState extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final bool isFiltered;

  const OrderEmptyState({
    super.key,
    required this.showActive,
    required this.isDark,
    required this.isFiltered,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: isFiltered
          ? Iconsax.search_normal
          : (showActive ? Iconsax.truck_fast : Iconsax.box),
      message: isFiltered
          ? 'No orders match your filters'
          : (showActive ? 'No active orders' : 'No completed orders'),
      subtitle: isFiltered
          ? 'Try adjusting or clearing your filters'
          : (showActive
          ? 'Tap + to book your first laundry service'
          : 'Completed orders will appear here'),
      isDark: isDark,
    );
  }
}
