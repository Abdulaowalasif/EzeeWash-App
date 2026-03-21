// lib/features/orders/screens/track_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../core/constants/app_color.dart';
import '../orders/domain/entities/order_entity.dart';
import '../orders/presentation/bloc/orders_bloc.dart';
import '../orders/presentation/bloc/orders_state.dart';

class TrackOrderScreen extends StatefulWidget {
  final String? orderId;

  const TrackOrderScreen({super.key, this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  bool _showTimeline = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: GoogleFonts.alexandria(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          OrderEntity? order;
          if (state is OrdersLoaded && widget.orderId != null) {
            try {
              order = state.orders.firstWhere((o) => o.id == widget.orderId);
            } catch (_) {}
          }

          // Fallback: use first active order if no ID passed
          if (order == null &&
              state is OrdersLoaded &&
              state.activeOrders.isNotEmpty) {
            order = state.activeOrders.first;
          }

          if (order == null) {
            return _EmptyState(isDark: isDark);
          }

          return _TrackContent(
            order: order,
            showTimeline: _showTimeline,
            isDark: isDark,
            onToggle: (v) => setState(() => _showTimeline = v),
          );
        },
      ),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _TrackContent extends StatelessWidget {
  final OrderEntity order;
  final bool showTimeline, isDark;
  final ValueChanged<bool> onToggle;

  const _TrackContent({
    required this.order,
    required this.showTimeline,
    required this.isDark,
    required this.onToggle,
  });

  // Derive progress from status as a fallback.
  // This ensures the bar always shows the correct position even if
  // the DB `progress` column hasn't been updated yet.
  double _progressForStatus(String status) {
    switch (status) {
      case 'pending':
        return 0.05;
      case 'confirmed':
        return 0.1;
      case 'picked_up':
        return 0.2;
      case 'in_process':
        return 0.4;
      case 'ready':
        return 0.6;
      case 'out_for_delivery':
        return 0.8;
      case 'delivered':
        return 1.0;
      case 'cancelled':
        return 0.0;
      default:
        return 0.0;
    }
  }

  // Use whichever is larger: DB value or status-derived value.
  // This prevents the bar from going backwards if progress is stale.
  double get _effectiveProgress {
    final fromStatus = _progressForStatus(order.status);
    final fromDb = order.progress;
    return fromDb > fromStatus ? fromDb : fromStatus;
  }

  String get _statusLabel {
    switch (order.status) {
      case AppConstants.orderPending:
        return 'Order Placed';
      case AppConstants.orderConfirmed:
        return 'Confirmed';
      case AppConstants.orderPickedUp:
        return 'Picked Up';
      case AppConstants.orderInProcess:
        return 'In Process';
      case AppConstants.orderReady:
        return 'Ready';
      case AppConstants.orderOutForDelivery:
        return 'Out for Delivery';
      case AppConstants.orderDelivered:
        return 'Delivered';
      case AppConstants.orderCancelled:
        return 'Cancelled';
      default:
        return order.status;
    }
  }

  Color get _statusColor {
    switch (order.status) {
      case AppConstants.orderDelivered:
        return AppColors.success;
      case AppConstants.orderCancelled:
        return AppColors.error;
      case AppConstants.orderOutForDelivery:
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: Column(
            children: [
              // ── Hero card ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ID',
                              style: GoogleFonts.alexandria(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${order.orderNumber}',
                              style: GoogleFonts.alexandria(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Iconsax.truck_fast,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: GoogleFonts.alexandria(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(_effectiveProgress * 100).toInt()}%',
                              style: GoogleFonts.alexandria(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _effectiveProgress),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              color: Colors.white,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeaderInfo(label: 'Service', value: order.serviceName),
                        const SizedBox(width: 12),
                        _HeaderInfo(label: 'Status', value: _statusLabel),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Toggle: Map / Timeline ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _ToggleBtn(
                      label: 'Live Map',
                      icon: Iconsax.location,
                      active: !showTimeline,
                      isDark: isDark,
                      onTap: () => onToggle(false),
                    ),
                    const SizedBox(width: 6),
                    _ToggleBtn(
                      label: 'Timeline',
                      icon: Iconsax.clock,
                      active: showTimeline,
                      isDark: isDark,
                      onTap: () => onToggle(true),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Map / Timeline ─────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: showTimeline
                    ? _TimelineView(order: order, isDark: isDark)
                    : _MapView(order: order, isDark: isDark),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Map view (static placeholder — add google_maps_flutter if needed) ────────

class _MapView extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  const _MapView({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('map'),
      children: [
        // Map placeholder
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Background grid pattern
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A2540)
                        : const Color(0xFFE8F0FE),
                  ),
                  child: CustomPaint(
                    painter: _GridPainter(isDark: isDark),
                    size: Size.infinite,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'Rider en route to ${order.storeName}',
                          style: GoogleFonts.alexandria(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Animated pulse dot
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live',
                          style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Delivery info
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Information',
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.location_on_rounded,
                color: AppColors.primary,
                title: 'Delivery Address',
                sub: order.deliveryAddress ?? order.pickupAddress,
                isDark: isDark,
              ),
              _InfoTile(
                icon: Iconsax.timer_1,
                color: AppColors.success,
                title: 'Estimated Delivery',
                sub: order.deliveryDate != null
                    ? '${order.deliveryDate!.day}/${order.deliveryDate!.month}/${order.deliveryDate!.year}${order.deliveryTime != null ? " at ${order.deliveryTime}" : ""}'
                    : 'To be updated',
                isDark: isDark,
              ),
              _InfoTile(
                icon: Iconsax.shop,
                color: const Color(0xFF8B5CF6),
                title: 'Processing Store',
                sub: order.storeName,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Timeline view ────────────────────────────────────────────────────────────

class _TimelineView extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  const _TimelineView({required this.order, required this.isDark});

  static List<Map<String, dynamic>> _defaultTimeline() => [
    {
      'title': 'Order Placed',
      'desc': 'Your order has been confirmed',
      'icon': Iconsax.tick_circle,
      'done': true,
    },
    {
      'title': 'Picked Up',
      'desc': 'Items collected from your location',
      'icon': Iconsax.bag_2,
      'done': false,
    },
    {
      'title': 'In Process',
      'desc': 'Being cleaned at the facility',
      'icon': Iconsax.refresh,
      'done': false,
    },
    {
      'title': 'Ready for Delivery',
      'desc': 'Packed and ready to go',
      'icon': Iconsax.box_1,
      'done': false,
    },
    {
      'title': 'Delivered',
      'desc': 'Order completed successfully',
      'icon': Iconsax.home_2,
      'done': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final steps = order.timeline.isNotEmpty
        ? order.timeline
              .asMap()
              .entries
              .map(
                (e) => {
                  'title': e.value.title,
                  'desc': e.value.description ?? '',
                  'icon': Iconsax.icon,
                  'done': e.value.isDone,
                },
              )
              .toList()
        : _defaultTimeline();

    return Column(
      key: const ValueKey('timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Timeline',
          style: GoogleFonts.alexandria(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 20),
        ...steps.asMap().entries.map(
          (e) => _TimelineTile(
            title: e.value['title'] as String,
            desc: e.value['desc'] as String,
            icon: e.value['icon'] as IconData,
            isDone: e.value['done'] as bool,
            isLast: e.key == steps.length - 1,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final bool isDone, isLast, isDark;

  const _TimelineTile({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isDone,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: isDone ? AppColors.gradient : null,
                    color: isDone
                        ? null
                        : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    boxShadow: isDone
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isDone ? Colors.white : Colors.grey.shade400,
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone
                          ? AppColors.primary
                          : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDone
                      ? AppColors.primary.withOpacity(0.2)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                  if (isDone) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: AppColors.success.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address screen ───────────────────────────────────────────────────────────

class _AddressScreen extends StatelessWidget {
  const _AddressScreen();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _HeaderInfo extends StatelessWidget {
  final String label, value;

  const _HeaderInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.alexandria(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.alexandria(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, isDark;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: active ? AppColors.gradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.grey, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.alexandria(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Iconsax.box_remove, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'No active order found',
          style: GoogleFonts.alexandria(fontSize: 16, color: Colors.grey),
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  final bool isDark;

  const _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primary).withOpacity(0.05)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
