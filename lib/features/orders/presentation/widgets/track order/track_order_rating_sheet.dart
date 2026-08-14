// lib/features/orders/presentation/widgets/track_order_rating_sheet.dart
//
// Bottom sheet for rating the rider after pickup or delivery.
// Shows animated stars, an optional comment field, and a success state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/order_event.dart';
import '../../bloc/orders_bloc.dart';
import '../../bloc/orders_state.dart';
import '../../screens/track_order_screen.dart' show RatingEvent;

class TrackOrderRatingSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final RatingEvent eventType;

  const TrackOrderRatingSheet({
    super.key,
    required this.order,
    required this.isDark,
    required this.eventType,
  });

  @override
  State<TrackOrderRatingSheet> createState() => _TrackOrderRatingSheetState();
}

class _TrackOrderRatingSheetState extends State<TrackOrderRatingSheet>
    with SingleTickerProviderStateMixin {
  int _stars = 0;
  bool _submitted = false;
  bool _loading = false;
  String _comment = '';

  late final AnimationController _bounceCtrl;
  late final List<Animation<double>> _starAnims;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starAnims = List.generate(
      5,
      (i) => Tween<double>(begin: 1.0, end: 1.4).animate(
        CurvedAnimation(
          parent: _bounceCtrl,
          curve: Interval(i * 0.1, i * 0.1 + 0.4, curve: Curves.elasticOut),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onStar(int s) {
    setState(() => _stars = s);
    _bounceCtrl.forward(from: 0);
  }

  String? get _targetRiderId => widget.eventType == RatingEvent.pickup
      ? (widget.order.pickupRiderId ?? widget.order.riderId)
      : (widget.order.deliveryRiderId ?? widget.order.riderId);

  Future<void> _markAsHandled() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.eventType == RatingEvent.pickup
        ? 'rated_pickup_${widget.order.id}'
        : 'rated_delivery_${widget.order.id}';
    await prefs.setBool(key, true);
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    final riderId = _targetRiderId;
    if (riderId == null) return;

    setState(() => _loading = true);

    context.read<OrdersBloc>().add(
      OrderSubmitRiderRating(
        orderId: widget.order.id,
        riderId: riderId,
        ratingType: widget.eventType == RatingEvent.pickup
            ? 'pickup'
            : 'delivery',
        stars: _stars.toDouble(),
        comment: _comment.trim().isEmpty ? null : _comment.trim(),
      ),
    );
  }

  void _onBlocStateChanged(BuildContext context, OrdersState state) async {
    if (state is OrdersError) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${state.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (_loading) {
      await _markAsHandled();
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: _onBlocStateChanged,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final name = widget.order.riderName ?? 'Your Rider';
    final photo = widget.order.riderAvatarUrl;

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        // Avatar (simple, no online badge needed here)
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 2.5,
            ),
          ),
          child: photo != null
              ? AppNetworkImage(
                  url: photo,
                  width: 72,
                  height: 72,
                  radius: 36, // Circular
                  fallbackIcon: Icons.motorcycle,
                )
              : _fallback(name),
        ),
        const SizedBox(height: 12),
        Text(
          widget.eventType == RatingEvent.pickup
              ? 'Rate Your Pickup'
              : 'Rate Your Delivery',
          style: GoogleFonts.alexandria(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'with $name',
          style: GoogleFonts.alexandria(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        // Star row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final s = i + 1;
            return AnimatedBuilder(
              animation: _starAnims[i],
              builder: (_, _) => Transform.scale(
                scale: _stars >= s ? _starAnims[i].value : 1.0,
                child: GestureDetector(
                  onTap: () => _onStar(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      _stars >= s
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 44,
                      color: _stars >= s
                          ? const Color(0xFFF59E0B)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        TextField(
          maxLines: 3,
          onChanged: (v) => _comment = v,
          style: GoogleFonts.alexandria(
            fontSize: 13,
            color: widget.isDark ? Colors.white : AppColors.lightText,
          ),
          decoration: InputDecoration(
            hintText: 'Leave a comment (optional)...',
            filled: true,
            fillColor: widget.isDark
                ? AppColors.darkBackground
                : const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _stars > 0 ? AppColors.gradient : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: (_stars > 0 && !_loading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Rating',
                          style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Container(
      key: const ValueKey('success'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (_, v, child) => Transform.scale(
                  scale: v,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradient,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Review Submitted!',
            style: GoogleFonts.alexandria(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Thank you for sharing your experience.\n'
            'Your feedback helps us provide a better service.',
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
              fontSize: 14,
              height: 1.5,
              color: widget.isDark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Community Contributor',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(String name) => Container(
    color: AppColors.primary.withValues(alpha: 0.12),
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'R',
      style: GoogleFonts.alexandria(
        color: AppColors.primary,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
