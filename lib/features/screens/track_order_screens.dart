// lib/features/screens/track_order_screens.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../core/constants/app_color.dart';
import '../orders/domain/entities/order_entity.dart';
import '../orders/presentation/bloc/orders_bloc.dart';
import '../orders/presentation/bloc/orders_state.dart';

// ─── Phase helper ─────────────────────────────────────────────────────────────
// Maps the DB status string into a UI phase that drives which panels are shown.
enum _OrderPhase {
  waiting,               // pending — no rider yet
  riderComingToPickup,   // confirmed — rider heading to customer
  atStore,               // picked_up — just arrived at store
  cleaning,              // in_process — washing / drying / ironing
  riderComingToDeliver,  // ready / out_for_delivery — rider heading back
  delivered,
  cancelled,
}

extension _PhaseX on String {
  _OrderPhase get phase {
    switch (this) {
      case AppConstants.orderPending:          return _OrderPhase.waiting;
      case AppConstants.orderConfirmed:        return _OrderPhase.riderComingToPickup;
      case AppConstants.orderPickedUp:         return _OrderPhase.atStore;
      case AppConstants.orderInProcess:        return _OrderPhase.cleaning;
      case AppConstants.orderReady:            return _OrderPhase.riderComingToDeliver;
      case AppConstants.orderOutForDelivery:   return _OrderPhase.riderComingToDeliver;
      case AppConstants.orderDelivered:        return _OrderPhase.delivered;
      case AppConstants.orderCancelled:        return _OrderPhase.cancelled;
      default:                                 return _OrderPhase.waiting;
    }
  }

  /// True only when a live rider position should be shown on the map.
  bool get mapVisible =>
      phase == _OrderPhase.riderComingToPickup ||
          phase == _OrderPhase.riderComingToDeliver;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

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
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Track Order',
            style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold, fontSize: 18)),
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
          if (order == null &&
              state is OrdersLoaded &&
              state.activeOrders.isNotEmpty) {
            order = state.activeOrders.first;
          }
          if (order == null) return _EmptyState(isDark: isDark);

          return TrackContent(
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

class TrackContent extends StatelessWidget {
  final OrderEntity order;
  final bool showTimeline, isDark;
  final ValueChanged<bool> onToggle;

  const TrackContent({
    required this.order,
    required this.showTimeline,
    required this.isDark,
    required this.onToggle,
  });

  static double progressForStatus(String s) {
    switch (s) {
      case 'pending':          return 0.05;
      case 'confirmed':        return 0.1;
      case 'picked_up':        return 0.2;
      case 'in_process':       return 0.4;
      case 'ready':            return 0.6;
      case 'out_for_delivery': return 0.8;
      case 'delivered':        return 1.0;
      default:                 return 0.0;
    }
  }

  double get progress {
    final s = progressForStatus(order.status);
    return order.progress > s ? order.progress : s;
  }

  String get _statusLabel {
    switch (order.status) {
      case AppConstants.orderPending:          return 'Order Placed';
      case AppConstants.orderConfirmed:        return 'Rider on the Way';
      case AppConstants.orderPickedUp:         return 'Dropped at Store';
      case AppConstants.orderInProcess:        return 'Cleaning in Progress';
      case AppConstants.orderReady:            return 'Ready for Delivery';
      case AppConstants.orderOutForDelivery:   return 'Out for Delivery';
      case AppConstants.orderDelivered:        return 'Delivered';
      case AppConstants.orderCancelled:        return 'Cancelled';
      default:                                 return order.status;
    }
  }


  static double effectiveProgress({
    required String status,
    required double dbProgress,
  }) {
    final fromStatus = progressForStatus(status);
    return dbProgress > fromStatus ? dbProgress : fromStatus;
  }


  _OrderPhase get _phase => order.status.phase;

  @override
  Widget build(BuildContext context) {
    // Terminal states → full-screen views
    if (_phase == _OrderPhase.delivered) {
      return _DeliveredView(order: order, isDark: isDark);
    }
    if (_phase == _OrderPhase.cancelled) {
      return _CancelledView(order: order, isDark: isDark);
    }

    final bool showCleaningPanel =
        _phase == _OrderPhase.atStore || _phase == _OrderPhase.cleaning;
    final bool showToggle = order.status.mapVisible;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context), vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints:
          BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Column(
            children: [
              // ── Hero progress card ─────────────────────────────
              _HeroCard(
                order: order,
                progress: progress,
                statusLabel: _statusLabel,
              ),

              const SizedBox(height: 18),

              // ── Phase banner ───────────────────────────────────
              _PhaseBanner(phase: _phase, isDark: isDark),

              const SizedBox(height: 18),

              // ── Map / Timeline toggle (only when rider is live) ─
              if (showToggle) ...[
                _Toggle(
                    showTimeline: showTimeline,
                    isDark: isDark,
                    onToggle: onToggle),
                const SizedBox(height: 18),
              ],

              // ── Main content panel ─────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showCleaningPanel
                    ? _CleaningPanel(
                  key: ValueKey('cleaning_${order.status}'),
                  phase: _phase,
                  order: order,
                  isDark: isDark,
                )
                    : showTimeline
                    ? TimelineView(
                  key: ValueKey('timeline_${order.status}'),
                  order: order,
                  isDark: isDark,
                )
                    : _MapPanel(
                  key: ValueKey('map_${order.status}'),
                  order: order,
                  isDark: isDark,
                  phase: _phase,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final OrderEntity order;
  final double progress;
  final String statusLabel;

  const _HeroCard(
      {required this.order,
        required this.progress,
        required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order ID',
                    style: GoogleFonts.alexandria(
                        color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 4),
                Text('#${order.orderNumber}',
                    style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ]),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Iconsax.truck_fast,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress',
                  style: GoogleFonts.alexandria(
                      color: Colors.white60, fontSize: 12)),
              Text('${(progress * 100).toInt()}%',
                  style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: v,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    color: Colors.white,
                    minHeight: 8),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _HeaderInfo(label: 'Service', value: order.serviceName),
            const SizedBox(width: 12),
            _HeaderInfo(label: 'Status', value: statusLabel),
          ]),
        ],
      ),
    );
  }
}

// ─── Phase banner ─────────────────────────────────────────────────────────────

class _PhaseBanner extends StatelessWidget {
  final _OrderPhase phase;
  final bool isDark;
  const _PhaseBanner({required this.phase, required this.isDark});

  _BannerCfg get _cfg {
    switch (phase) {
      case _OrderPhase.waiting:
        return _BannerCfg(Iconsax.clock, AppColors.warning,
            'Looking for a Rider',
            'We\'re assigning a rider to your order.');
      case _OrderPhase.riderComingToPickup:
        return _BannerCfg(Iconsax.car, AppColors.primary,
            'Rider on the Way',
            'Your rider is heading to pick up your items.');
      case _OrderPhase.atStore:
        return _BannerCfg(Iconsax.shop, const Color(0xFF8B5CF6),
            'Items at the Store',
            'Your laundry has been dropped at the cleaning facility.');
      case _OrderPhase.cleaning:
        return _BannerCfg(Iconsax.refresh, AppColors.info,
            'Cleaning in Progress',
            'Our team is washing, drying and ironing your laundry.');
      case _OrderPhase.riderComingToDeliver:
        return _BannerCfg(Iconsax.truck_fast, const Color(0xFF8B5CF6),
            'On the Way to You',
            'Your fresh laundry is headed back to your address.');
      default:
        return _BannerCfg(Iconsax.info_circle, AppColors.primary,
            'Processing', 'Your order is being handled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: c.color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: c.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(c.icon, color: c.color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title,
                style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 3),
            Text(c.subtitle,
                style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext)),
          ]),
        ),
      ]),
    );
  }
}

class _BannerCfg {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _BannerCfg(this.icon, this.color, this.title, this.subtitle);
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool showTimeline, isDark;
  final ValueChanged<bool> onToggle;
  const _Toggle(
      {required this.showTimeline,
        required this.isDark,
        required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _ToggleBtn(
            label: 'Live Map',
            icon: Iconsax.location,
            active: !showTimeline,
            isDark: isDark,
            onTap: () => onToggle(false)),
        const SizedBox(width: 6),
        _ToggleBtn(
            label: 'Timeline',
            icon: Iconsax.clock,
            active: showTimeline,
            isDark: isDark,
            onTap: () => onToggle(true)),
      ]),
    );
  }
}

// ─── Cleaning panel ───────────────────────────────────────────────────────────

class _CleaningPanel extends StatefulWidget {
  final _OrderPhase phase;
  final OrderEntity order;
  final bool isDark;

  const _CleaningPanel(
      {super.key,
        required this.phase,
        required this.order,
        required this.isDark});

  @override
  State<_CleaningPanel> createState() => _CleaningPanelState();
}

class _CleaningPanelState extends State<_CleaningPanel>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bubbleCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cleaning'),
      children: [
        // ── Animation container ────────────────────────────────
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: widget.isDark
                    ? AppColors.darkBorder
                    : AppColors.primary.withOpacity(0.15)),
          ),
          child: Stack(alignment: Alignment.center, children: [
            // Outer pulse ring
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: 0.95 + 0.1 * _pulseCtrl.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05)),
                ),
              ),
            ),
            // Inner pulse ring
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: 1.0 +
                    0.07 * math.sin(_pulseCtrl.value * math.pi),
                child: Container(
                  width: 115,
                  height: 115,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.09)),
                ),
              ),
            ),
            // Spinning arc
            AnimatedBuilder(
              animation: _spinCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _spinCtrl.value * 2 * math.pi,
                child: CustomPaint(
                    size: const Size(90, 90), painter: _ArcPainter()),
              ),
            ),
            // Centre icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.gradient),
              child: Icon(
                widget.phase == _OrderPhase.atStore
                    ? Iconsax.shop
                    : Iconsax.refresh,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Floating bubbles
            ..._bubbles(),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Cleaning process steps ─────────────────────────────
        _CleaningSteps(phase: widget.phase, isDark: widget.isDark),

        const SizedBox(height: 20),

        // ── Delivery info ──────────────────────────────────────
        _DeliveryInfoCard(order: widget.order, isDark: widget.isDark),
      ],
    );
  }

  List<Widget> _bubbles() {
    const positions = [
      Offset(-80, -60), Offset(75, -55),
      Offset(-65, 55),  Offset(72, 60),
      Offset(-10, -88), Offset(5, 84),
    ];
    return positions.asMap().entries.map((e) {
      final phase = e.key / positions.length;
      return AnimatedBuilder(
        animation: _bubbleCtrl,
        builder: (_, __) {
          final t = (_bubbleCtrl.value + phase) % 1.0;
          final opacity = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.65;
          final dy = -12.0 * math.sin(t * math.pi);
          return Transform.translate(
            offset: Offset(e.value.dx, e.value.dy + dy),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 10 + (e.key % 3) * 4.0,
                height: 10 + (e.key % 3) * 4.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.4)),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// Custom painter for spinning gradient arc
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
          colors: [AppColors.primary, Colors.transparent])
          .createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter _) => false;
}

// ─── Cleaning process steps ───────────────────────────────────────────────────

class _CleaningSteps extends StatelessWidget {
  final _OrderPhase phase;
  final bool isDark;
  const _CleaningSteps({required this.phase, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepDef(
        icon: Iconsax.shop,
        label: 'Dropped\nat Store',
        done: phase != _OrderPhase.waiting &&
            phase != _OrderPhase.riderComingToPickup,
      ),
      _StepDef(
        icon: Iconsax.drop,
        label: 'Wash &\nClean',
        done: phase == _OrderPhase.cleaning ||
            phase == _OrderPhase.riderComingToDeliver ||
            phase == _OrderPhase.delivered,
        active: phase == _OrderPhase.atStore || phase == _OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.flash_1,
        label: 'Dry &\nIron',
        done: phase == _OrderPhase.riderComingToDeliver ||
            phase == _OrderPhase.delivered,
        active: phase == _OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.box_1,
        label: 'Packed\n& Ready',
        done: phase == _OrderPhase.riderComingToDeliver ||
            phase == _OrderPhase.delivered,
        active: phase == _OrderPhase.cleaning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cleaning Process',
            style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 18),
        Row(
          children: steps.asMap().entries.map((e) {
            final s = e.value;
            final isLast = e.key == steps.length - 1;
            return Expanded(
              child: Row(children: [
                Expanded(
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: s.done ? AppColors.gradient : null,
                        color: s.done
                            ? null
                            : s.active
                            ? AppColors.primary.withOpacity(0.12)
                            : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100),
                        border: s.active && !s.done
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        s.done ? Icons.check_rounded : s.icon,
                        color: s.done
                            ? Colors.white
                            : s.active
                            ? AppColors.primary
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(s.label,
                        style: GoogleFonts.alexandria(
                          fontSize: 10,
                          fontWeight: s.done || s.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: s.done
                              ? AppColors.primary
                              : s.active
                              ? (isDark
                              ? Colors.white
                              : AppColors.lightText)
                              : Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.center),
                  ]),
                ),
                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        gradient: s.done ? AppColors.gradient : null,
                        color: s.done
                            ? null
                            : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class _StepDef {
  final IconData icon;
  final String label;
  final bool done, active;
  const _StepDef(
      {required this.icon,
        required this.label,
        this.done = false,
        this.active = false});
}

// ─── Map panel ────────────────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;

  const _MapPanel(
      {super.key,
        required this.order,
        required this.isDark,
        required this.phase});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('map'),
      children: [
        MapView(order: order, isDark: isDark, phase: phase),
        const SizedBox(height: 18),
        _DeliveryInfoCard(order: order, isDark: isDark),
      ],
    );
  }
}

// ─── Delivery info card ───────────────────────────────────────────────────────

class _DeliveryInfoCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _DeliveryInfoCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Delivery Information',
            style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.lightText)),
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
              ? '${order.deliveryDate!.day}/${order.deliveryDate!.month}/${order.deliveryDate!.year}'
              '${order.deliveryTime != null ? " at ${order.deliveryTime}" : ""}'
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
      ]),
    );
  }
}

// ─── Delivered view ───────────────────────────────────────────────────────────

class _DeliveredView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  const _DeliveredView({required this.order, required this.isDark});

  @override
  State<_DeliveredView> createState() => _DeliveredViewState();
}

class _DeliveredViewState extends State<_DeliveredView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context), vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints:
          BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Column(children: [
            const SizedBox(height: 24),

            // Animated checkmark
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF059669)]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                ),
              ),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                Text('Order Delivered!',
                    style: GoogleFonts.alexandria(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.lightText)),
                const SizedBox(height: 8),
                Text(
                  'Your laundry has been delivered.\nThank you for using EzeeWash!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alexandria(
                      fontSize: 14,
                      color: widget.isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      height: 1.5),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // Order summary
            FadeTransition(
              opacity: _fade,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.success.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.success.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(children: [
                  _SummaryRow(
                      icon: Icons.tag_rounded,
                      label: 'Order',
                      value: '#${widget.order.orderNumber}',
                      isDark: widget.isDark),
                  const SizedBox(height: 12),
                  _SummaryRow(
                      icon: Iconsax.drop,
                      label: 'Service',
                      value: widget.order.serviceName,
                      isDark: widget.isDark),
                  const SizedBox(height: 12),
                  _SummaryRow(
                      icon: Iconsax.shop,
                      label: 'Store',
                      value: widget.order.storeName,
                      isDark: widget.isDark),
                  const SizedBox(height: 12),
                  _SummaryRow(
                      icon: Iconsax.money,
                      label: 'Total Paid',
                      value: '৳${widget.order.totalPrice.toStringAsFixed(0)}',
                      isDark: widget.isDark,
                      highlight: true),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            FadeTransition(
              opacity: _fade,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.alexandria(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── Cancelled view ───────────────────────────────────────────────────────────

class _CancelledView extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  const _CancelledView({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(0.12)),
            child: const Icon(Icons.cancel_outlined,
                color: AppColors.error, size: 56),
          ),
          const SizedBox(height: 20),
          Text('Order Cancelled',
              style: GoogleFonts.alexandria(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightText)),
          const SizedBox(height: 8),
          Text('This order has been cancelled.',
              style: GoogleFonts.alexandria(
                  fontSize: 13,
                  color:
                  isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Go Back',
                style: GoogleFonts.alexandria(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

// ─── Timeline view ────────────────────────────────────────────────────────────

class TimelineView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;

  const TimelineView({required this.order, required this.isDark, Key? key})
      : super(key: key);

  static List<Map<String, dynamic>> steps() => [
    {'title': 'Order Placed',     'desc': 'Your order has been confirmed',          'icon': Iconsax.tick_circle},
    {'title': 'Rider Assigned',   'desc': 'Rider heading to pick up your items',    'icon': Iconsax.car},
    {'title': 'Picked Up',        'desc': 'Items collected from your location',     'icon': Iconsax.bag_2},
    {'title': 'At the Store',     'desc': 'Dropped at the cleaning facility',       'icon': Iconsax.shop},
    {'title': 'Cleaning',         'desc': 'Being washed, dried and ironed',         'icon': Iconsax.refresh},
    {'title': 'Ready',            'desc': 'Packed and ready to go',                 'icon': Iconsax.box_1},
    {'title': 'Out for Delivery', 'desc': 'Rider is on the way to you',             'icon': Iconsax.truck_fast},
    {'title': 'Delivered',        'desc': 'Order completed successfully',           'icon': Iconsax.home_2},
  ];

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  late List<bool> _done;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final idx = _toIndex(widget.order.status);
    _done = List.generate(TimelineView.steps().length, (i) => i <= idx);
  }

  @override
  void didUpdateWidget(TimelineView old) {
    super.didUpdateWidget(old);
    if (old.order.status != widget.order.status) setState(_init);
  }

  int _toIndex(String s) {
    switch (s) {
      case AppConstants.orderPending:          return 0;
      case AppConstants.orderConfirmed:        return 1;
      case AppConstants.orderPickedUp:         return 3;
      case AppConstants.orderInProcess:        return 4;
      case AppConstants.orderReady:            return 5;
      case AppConstants.orderOutForDelivery:   return 6;
      case AppConstants.orderDelivered:        return 7;
      default:                                 return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = TimelineView.steps();
    return Column(
      key: const ValueKey('timeline'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Timeline',
            style: GoogleFonts.alexandria(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 20),
        ...list.asMap().entries.map((e) => _TimelineTile(
          title: e.value['title'] as String,
          desc: e.value['desc'] as String,
          icon: e.value['icon'] as IconData,
          isDone: _done[e.key],
          isLast: e.key == list.length - 1,
          isDark: widget.isDark,
        )),
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 48,
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
                      blurRadius: 8)
                ]
                    : [],
              ),
              child: Icon(icon,
                  color: isDone ? Colors.white : Colors.grey.shade400,
                  size: 18),
            ),
            if (!isLast)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 2,
                  color: isDone
                      ? AppColors.primary
                      : (isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDone
                      ? AppColors.primary.withOpacity(0.2)
                      : (isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder)),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.alexandria(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                          isDark ? Colors.white : AppColors.lightText)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc,
                        style: GoogleFonts.alexandria(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext)),
                  ],
                  if (isDone) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.check_circle,
                          size: 12,
                          color: AppColors.success.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text('Completed',
                          style: GoogleFonts.alexandria(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ],
                ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Map view ─────────────────────────────────────────────────────────────────

class MapView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;

  const MapView(
      {required this.order, required this.isDark, required this.phase});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _cc = Completer();
  GoogleMapController? _mapCtrl;
  LatLng? _customerLoc;
  LatLng? _riderPos;
  bool _loading = true;
  bool _denied = false;
  StreamSubscription? _sub;

  static const LatLng _dhaka = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (old.order.status != widget.order.status) _fit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.order.riderLat != null && widget.order.riderLng != null) {
      _riderPos = LatLng(widget.order.riderLat!, widget.order.riderLng!);
    }

    try {
      final addr = widget.order.deliveryAddress ?? widget.order.pickupAddress;
      if (addr.isNotEmpty) {
        final locs = await locationFromAddress(addr);
        if (locs.isNotEmpty) {
          _customerLoc = LatLng(locs.first.latitude, locs.first.longitude);
        }
      }
    } catch (_) {}

    if (_customerLoc == null) {
      try {
        final svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (svcEnabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
            _customerLoc = LatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {}
    }

    _listenRider();

    if (mounted) {
      setState(() {
        _loading = false;
        _denied = _customerLoc == null;
      });
      _fit();
    }
  }

  void _listenRider() {
    _sub = Supabase.instance.client
        .from('rider_locations')
        .stream(primaryKey: ['id'])
        .eq('order_id', widget.order.id)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final lat = (data.first['latitude'] as num).toDouble();
        final lng = (data.first['longitude'] as num).toDouble();
        setState(() => _riderPos = LatLng(lat, lng));
        _fit();
      }
    });
  }

  Future<void> _fit() async {
    if (_customerLoc == null) return;
    final ctrl = await _cc.future;
    if (_riderPos != null) {
      final sw = LatLng(
        math.min(_customerLoc!.latitude, _riderPos!.latitude),
        math.min(_customerLoc!.longitude, _riderPos!.longitude),
      );
      final ne = LatLng(
        math.max(_customerLoc!.latitude, _riderPos!.latitude),
        math.max(_customerLoc!.longitude, _riderPos!.longitude),
      );
      await ctrl.animateCamera(
          CameraUpdate.newLatLngBounds(
              LatLngBounds(southwest: sw, northeast: ne), 70));
    } else {
      await ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(_customerLoc!, 15));
    }
  }

  Set<Marker> get _markers {
    final m = <Marker>{};
    if (_customerLoc != null) {
      m.add(Marker(
        markerId: const MarkerId('customer'),
        position: _customerLoc!,
        infoWindow: InfoWindow(
            title: widget.phase == _OrderPhase.riderComingToDeliver
                ? 'Your Address (Delivery)'
                : 'Your Address (Pickup)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
      ));
    }
    if (_riderPos != null) {
      m.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderPos!,
        infoWindow: InfoWindow(
            title: widget.phase == _OrderPhase.riderComingToDeliver
                ? 'Rider • Delivering'
                : 'Rider • Coming to Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
      ));
    }
    return m;
  }

  Set<Polyline> get _polylines {
    if (_customerLoc == null || _riderPos == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_riderPos!, _customerLoc!],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      )
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              borderRadius: BorderRadius.circular(24),
              boxShadow: widget.isDark
                  ? []
                  : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _loading
                  ? _loadingOverlay()
                  : _denied
                  ? _deniedOverlay()
                  : GoogleMap(
                initialCameraPosition: CameraPosition(
                    target: _customerLoc ?? _dhaka, zoom: 14),
                onMapCreated: (ctrl) {
                  if (!_cc.isCompleted) _cc.complete(ctrl);
                  _mapCtrl = ctrl;
                  if (widget.isDark) {
                    ctrl.setMapStyle(AppConstants.darkMapStyle);
                  }
                  _fit();
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                gestureRecognizers: {
                  Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer()),
                },
              ),
            ),
          ),
        ),

        // Phase label badge
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  widget.phase == _OrderPhase.riderComingToDeliver
                      ? Iconsax.truck_fast
                      : Iconsax.car,
                  color: Colors.white,
                  size: 13),
              const SizedBox(width: 5),
              Text(
                  widget.phase == _OrderPhase.riderComingToDeliver
                      ? 'Rider delivering'
                      : 'Rider picking up',
                  style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _loadingOverlay() => Container(
    color: widget.isDark
        ? const Color(0xFF1A2540)
        : const Color(0xFFE8F0FE),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2.5),
        const SizedBox(height: 14),
        Text('Locating address…',
            style: GoogleFonts.alexandria(fontSize: 13)),
      ]),
    ),
  );

  Widget _deniedOverlay() => Container(
    color: widget.isDark
        ? const Color(0xFF1A2540)
        : const Color(0xFFE8F0FE),
    child: Center(
        child: Text('Could not find address',
            style: GoogleFonts.alexandria(fontSize: 13))),
  );
}

// ─── Small shared widgets ─────────────────────────────────────────────────────

class _HeaderInfo extends StatelessWidget {
  final String label, value;
  const _HeaderInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.alexandria(
                color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.alexandria(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, isDark;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
        required this.icon,
        required this.active,
        required this.isDark,
        required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
            gradient: active ? AppColors.gradient : null,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: active ? Colors.white : Colors.grey, size: 16),
              const SizedBox(width: 7),
              Text(label,
                  style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : Colors.grey,
                      fontSize: 13)),
            ]),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  final bool isDark;

  const _InfoTile(
      {required this.icon,
        required this.color,
        required this.title,
        required this.sub,
        required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.alexandria(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext)),
          Text(sub,
              style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightText)),
        ]),
      ),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark, highlight;

  const _SummaryRow(
      {required this.icon,
        required this.label,
        required this.value,
        required this.isDark,
        this.highlight = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.success.withOpacity(0.12)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon,
          size: 16,
          color: highlight
              ? AppColors.success
              : (isDark
              ? Colors.grey.shade400
              : Colors.grey.shade600)),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Text(label,
          style: GoogleFonts.alexandria(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext)),
    ),
    Text(value,
        style: GoogleFonts.alexandria(
            fontSize: highlight ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: highlight
                ? AppColors.success
                : (isDark ? Colors.white : AppColors.lightText))),
  ]);
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Iconsax.box_remove, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text('No active order found',
          style:
          GoogleFonts.alexandria(fontSize: 16, color: Colors.grey)),
    ]),
  );
}