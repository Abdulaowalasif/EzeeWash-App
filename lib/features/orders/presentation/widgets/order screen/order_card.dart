// lib/features/orders/presentation/widgets/order_screen/order_card.dart
//
// An expandable card showing a single order's summary, progress bar,
// action buttons (Review/Details and Reorder/Cancel), and inline timeline.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/order_status.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../routes/routes_name.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/order_event.dart';
import '../../bloc/orders_bloc.dart';
import '../../bloc/orders_state.dart';
import '../../models/reorder_params.dart';
import 'order_flowing_timeline.dart';
import 'order_reorder_sheet.dart';
import 'order_review_sheet.dart';
import 'order_service_image.dart';

class OrderCard extends StatefulWidget {
  final OrderEntity order;
  final bool isHistory;
  final bool isDark;
  final VoidCallback onPress;

  const OrderCard({
    super.key,
    required this.order,
    required this.isHistory,
    required this.isDark,
    required this.onPress,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;

  void _confirmCancel(BuildContext ctx) {
    AppConfirmDialog.show(
      ctx,
      title: 'Cancel Order?',
      message:
          'Cancel order #${widget.order.orderNumber}? This cannot be undone.',
      cancelLabel: 'Keep Order',
      confirmLabel: 'Yes, Cancel',
      confirmColor: AppColors.error,
      onConfirm: () =>
          ctx.read<OrdersBloc>().add(OrderCancelRequested(widget.order.id)),
    );
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OrderReviewSheet(order: widget.order, isDark: widget.isDark),
    );
  }

  Future<void> _handleReorder(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          OrderReorderSheet(order: widget.order, isDark: widget.isDark),
    );
    if (result == null || !context.mounted) return;

    context.push(
      RoutesName.placeOrdersNavigate,
      extra: ReorderParams(
        serviceId: widget.order.serviceId,
        storeId: widget.order.storeId,
        serviceName: widget.order.serviceName,
        storeName: widget.order.storeName,
        itemCount: widget.order.itemCount,
        totalPrice: widget.order.totalPrice,
        discountAmount:
            widget.order.discountAmount, // ── FIXED: PASS DISCOUNT ──
        pickupAddress: widget.order.pickupAddress,
        deliveryAddress: widget.order.deliveryAddress,
        specialInstructions: widget.order.specialInstructions,
        pickupDate: result['pickupDate'] as DateTime,
        pickupTime: result['pickupTime'] as String,
        deliveryDate: result['deliveryDate'] as DateTime,
        deliveryTime: result['deliveryTime'] as String,
        paymentMethod: widget.order.paymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final displayStatus = OrderStatus.getDisplayStatus(o.status);
    final statusColor = OrderStatus.getColor(displayStatus);
    final currentLevel = OrderStatus.getStepCompletionOrder(displayStatus);
    final progress = o.progress.clamp(0.0, 1.0);
    final canCancel =
        currentLevel <
        OrderStatus.getStepCompletionOrder(OrderStatus.assignPickup);

    return GestureDetector(
      onTap: widget.onPress,
      child: AppCard(
        isDark: widget.isDark,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                OrderServiceImage(
                  imageUrl: o.serviceImageUrl,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.serviceName,
                        style: AppTextStyles.cardTitle(
                          widget.isDark,
                        ).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        o.storeName,
                        style: AppTextStyles.subtitle(widget.isDark),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            '#${o.orderNumber}',
                            style: AppTextStyles.captionMedium(
                              widget.isDark,
                            ).copyWith(color: AppColors.primary, fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              OrderStatus.format(displayStatus).toUpperCase(),
                              style: AppTextStyles.statusBadge(statusColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳${o.totalPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.priceLarge,
                    ),
                    Text(
                      '${o.itemCount} pcs',
                      style: AppTextStyles.caption(widget.isDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Progress bar ────────────────────────────────────────────────
            _ProgressBar(progress: progress, isDark: widget.isDark),
            const SizedBox(height: 16),

            // ── Action buttons ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    isHistory: widget.isHistory,
                    expanded: _expanded,
                    isDark: widget.isDark,
                    onReview: () => _showReviewSheet(context),
                    onToggleDetails: () =>
                        setState(() => _expanded = !_expanded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryButton(
                    isHistory: widget.isHistory,
                    canCancel: canCancel,
                    isDark: widget.isDark,
                    orderId: widget.order.id,
                    onReorder: () => _handleReorder(context),
                    onCancel: _confirmCancel,
                  ),
                ),
              ],
            ),

            // ── Inline timeline ─────────────────────────────────────────────
            if (_expanded && !widget.isHistory) ...[
              const SizedBox(height: 24),
              Divider(
                color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              const SizedBox(height: 20),
              Text(
                'Order Tracking',
                style: AppTextStyles.cardTitle(widget.isDark),
              ),
              const SizedBox(height: 24),
              if (displayStatus == OrderStatus.cancelled)
                Row(
                  children: [
                    const Icon(Icons.cancel_rounded, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(
                      'This order was cancelled.',
                      style: AppTextStyles.body(widget.isDark).copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                OrderFlowingTimeline(
                  currentLevel: currentLevel,
                  isDark: widget.isDark,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _ProgressBar({required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 6,
        color: isDark ? Colors.white12 : Colors.grey.shade200,
        child: LayoutBuilder(
          builder: (_, c) => Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              width: c.maxWidth * progress,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Secondary button (Details / Review) ─────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final bool isHistory;
  final bool expanded;
  final bool isDark;
  final VoidCallback onReview;
  final VoidCallback onToggleDetails;

  const _SecondaryButton({
    required this.isHistory,
    required this.expanded,
    required this.isDark,
    required this.onReview,
    required this.onToggleDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (isHistory) {
      return OutlinedButton.icon(
        icon: const Icon(
          Icons.star_outline_rounded,
          color: AppColors.primary,
          size: 18,
        ),
        onPressed: onReview,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        label: Text(
          'Review',
          style: AppTextStyles.buttonOutline.copyWith(fontSize: 12),
        ),
      );
    }
    return OutlinedButton.icon(
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.remove_red_eye_outlined,
        color: AppColors.primary,
        size: 18,
      ),
      onPressed: onToggleDetails,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      label: Text(
        expanded ? 'Hide' : 'Details',
        style: AppTextStyles.buttonOutline.copyWith(fontSize: 12),
      ),
    );
  }
}

// ─── Primary button (Reorder / Cancel) ───────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final bool isHistory;
  final bool canCancel;
  final bool isDark;
  final String orderId;
  final VoidCallback onReorder;
  final void Function(BuildContext) onCancel;

  const _PrimaryButton({
    required this.isHistory,
    required this.canCancel,
    required this.isDark,
    required this.orderId,
    required this.onReorder,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isHistory) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          icon: const Icon(
            Icons.replay_outlined,
            color: Colors.white,
            size: 16,
          ),
          onPressed: onReorder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          label: Text('Reorder', style: AppTextStyles.buttonSmall),
        ),
      );
    }

    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (ctx, bState) {
        final cancelling =
            bState is OrderCancelling && bState.orderId == orderId;
        final disabled = cancelling || !canCancel;
        final bgColor = disabled
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : AppColors.error;
        final textColor = disabled ? Colors.grey.shade500 : Colors.white;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled
              ? () {
                  if (!canCancel && !cancelling) {
                    AppSnackBar.show(
                      context,
                      'Order cannot be cancelled after a rider is assigned.',
                      type: SnackBarType.error,
                    );
                  }
                }
              : () => onCancel(ctx),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton.icon(
              onPressed: null,
              icon: cancelling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.cancel_outlined, color: textColor, size: 16),
              label: Text(
                cancelling ? 'Cancelling…' : 'Cancel',
                style: AppTextStyles.buttonSmall.copyWith(color: textColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
