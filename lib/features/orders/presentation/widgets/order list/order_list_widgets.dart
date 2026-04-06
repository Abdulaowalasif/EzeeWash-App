// lib/features/orders/presentation/widgets/order_list/order_list_widgets.dart
//
// All UI widgets for the order list screen (order_screen.dart), extracted
// into one focused file so the screen only holds state + BLoC wiring.
//
// Exports:
//   OrderCard          – rich order tile with status badge, action buttons
//   OrdersToggle       – Active / History pill toggle
//   OrderActiveFilterBar – horizontal scrolling active-filter chips
//   OrdersShimmer      – skeleton loading state
//   OrderEmptyState    – empty placeholder

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/order_status.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_status_badge.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../routes/routes_name.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/order_event.dart';
import '../../bloc/orders_bloc.dart';

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
    final displayStatus =
        OrderStatus.getDisplayStatus(order.status);
    final statusColor = OrderStatus.getColor(displayStatus);
    final progress =
        OrderStatus.getProgress(order.status).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onPress,
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  // Service image/icon
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
                              errorWidget: (_, __, ___) => const Icon(
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
                        Text(
                          order.serviceName,
                          style: GoogleFonts.alexandria(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '#${order.orderNumber} · ${order.storeName}',
                          style: GoogleFonts.alexandria(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(status: order.status),
                ],
              ),
            ),
            // Progress bar (active orders only)
            if (!isHistory)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
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
            // Footer
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
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _FooterInfo(
                    icon: Iconsax.calendar_1,
                    label: _fmtDate(order.createdAt),
                    isDark: isDark,
                  ),
                  _FooterInfo(
                    icon: Iconsax.money,
                    label:
                        '৳${order.totalPrice.toStringAsFixed(0)}',
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

  String _fmtDate(DateTime d) =>
      DateFormat('dd MMM yyyy').format(d);
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
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              fontWeight: highlight
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: highlight
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext),
            ),
          ),
        ],
      );
}

class _TrackButton extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _TrackButton({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push(
            RoutesName.trackOrdersNavigate,
            extra: order.id),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Track',
              style: GoogleFonts.alexandria(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              )),
        ),
      );
}

class _ReorderButton extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _ReorderButton(
      {required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push(
            RoutesName.placeOrdersNavigate,
            extra: order),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text('Reorder',
              style: GoogleFonts.alexandria(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              )),
        ),
      );
}

// ─── OrdersToggle ─────────────────────────────────────────────────────────────

class OrdersToggle extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const OrdersToggle({
    super.key,
    required this.showActive,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Active',
            active: showActive,
            onTap: () => onChanged(true),
          ),
          _ToggleBtn(
            label: 'History',
            active: !showActive,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: active ? AppColors.gradient : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.alexandria(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
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
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
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
                      style: GoogleFonts.alexandria(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      )),
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
            baseColor:
                isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor:
                isDark ? Colors.grey[700]! : Colors.grey[100]!,
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
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (_, __) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24)),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Iconsax.search_normal : Iconsax.box,
            size: 64,
            color: isDark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No matches'
                : (showActive
                    ? 'No active orders'
                    : 'No history'),
            style: GoogleFonts.alexandria(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    );
  }
}
