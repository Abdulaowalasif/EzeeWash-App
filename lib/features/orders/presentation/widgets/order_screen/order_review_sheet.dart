// lib/features/orders/presentation/widgets/order_screen/order_review_sheet.dart
//
// Bottom sheet for submitting a star rating + comment for a completed order.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/order_event.dart';
import '../../bloc/orders_bloc.dart';
import '../../bloc/orders_state.dart';

class OrderReviewSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;

  const OrderReviewSheet({
    super.key,
    required this.order,
    required this.isDark,
  });

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  final _ctrl = TextEditingController();
  double _rating = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Please write a comment.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    context.read<OrdersBloc>().add(
      OrderSubmitServiceReview(
        orderId: widget.order.id,
        serviceId: widget.order.serviceId,
        rating: _rating,
        comment: comment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrdersError) {
          if (mounted) {
            setState(() {
              _submitting = false;
              _error =
                  state.message.contains('duplicate') ||
                      state.message.contains('unique')
                  ? 'You have already reviewed this service.'
                  : 'Failed to submit. Please try again.';
            });
          }
        } else if (_submitting) {
          // If the state changes and we were submitting without an error, assume success
          if (mounted) {
            Navigator.pop(context);
            AppSnackBar.show(context, 'Review submitted successfully!');
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSheetHandle(isDark: widget.isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Write a Review',
                            style: AppTextStyles.heading(
                              widget.isDark,
                            ).copyWith(fontSize: 17),
                          ),
                          Text(
                            widget.order.serviceName,
                            style: AppTextStyles.subtitle(widget.isDark),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: widget.isDark ? Colors.white54 : Colors.black38,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StarRatingRow(
                      rating: _rating,
                      isDark: widget.isDark,
                      onChanged: (r) => setState(() => _rating = r),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _ctrl,
                      maxLines: 4,
                      maxLength: 500,
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText: 'Share your experience…',
                        hintStyle: AppTextStyles.hint(widget.isDark),
                        filled: true,
                        fillColor: widget.isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFF),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: widget.isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        counterStyle: AppTextStyles.caption(widget.isDark),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.caption(
                                widget.isDark,
                              ).copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppGradientButton(
                      label: 'Submit Review',
                      onPressed: _submitting ? null : _submit,
                      isLoading: _submitting,
                      verticalPadding: 15,
                      borderRadius: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Star rating row ──────────────────────────────────────────────────────────

class _StarRatingRow extends StatelessWidget {
  final double rating;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _StarRatingRow({
    required this.rating,
    required this.isDark,
    required this.onChanged,
  });

  String _label(double r) {
    if (r >= 5) return 'Excellent ✨';
    if (r >= 4) return 'Very Good 👍';
    if (r >= 3) return 'Good 😊';
    if (r >= 2) return 'Fair 😐';
    return 'Poor 😞';
  }

  Color _labelColor(double r) {
    if (r >= 4) return AppColors.success;
    if (r >= 3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final on = i < rating;
              return GestureDetector(
                onTap: () => onChanged((i + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      on ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey('$i-$on'),
                      color: on
                          ? const Color(0xFFFBBF24)
                          : (isDark ? Colors.white24 : Colors.black26),
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _label(rating),
              key: ValueKey(rating),
              style: AppTextStyles.body(isDark).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _labelColor(rating),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
