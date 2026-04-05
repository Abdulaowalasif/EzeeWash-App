// lib/features/orders/presentation/screens/track_order_screen.dart
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
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/order_status.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';

// ─── Real-Life Phase Logic ───────────────────────────────────────────────────
enum _OrderPhase {
  waiting,
  riderComingToPickup,
  riderHeadingToStore,
  atStore,
  cleaning,
  ready,
  riderComingToDeliver,
  delivered,
  cancelled,
}

extension _PhaseX on String {
  _OrderPhase get phase {
    final displayStatus = OrderStatus.getDisplayStatus(this);
    switch (displayStatus) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return _OrderPhase.waiting;
      case OrderStatus.assignPickup:
        return _OrderPhase.riderComingToPickup;
      case OrderStatus.pickedUp:
        return _OrderPhase.riderHeadingToStore;
      case OrderStatus.dropped:
      case OrderStatus.received:
        return _OrderPhase.atStore;
      case OrderStatus.inProcess:
        return _OrderPhase.cleaning;
      case OrderStatus.ready:
        return _OrderPhase.ready;
      case OrderStatus.outForDelivery:
        return _OrderPhase.riderComingToDeliver;
      case OrderStatus.delivered:
        return _OrderPhase.delivered;
      case OrderStatus.cancelled:
        return _OrderPhase.cancelled;
      default:
        return _OrderPhase.waiting;
    }
  }
}

enum _RatingEvent { pickup, delivery }

class _RatingMemory {
  bool shownForPickup = false;
  bool shownForDelivery = false;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TrackOrderScreen extends StatefulWidget {
  final String? orderId;

  const TrackOrderScreen({super.key, this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _ratingMem = _RatingMemory();

  StreamSubscription? _orderSub;
  String? _trackingOrderId;
  String? _liveStatus;
  double? _liveProgress;
  String? _livePickupRiderId;
  String? _liveDeliveryRiderId;

  @override
  void dispose() {
    _orderSub?.cancel();
    super.dispose();
  }

  void _listenToOrderUpdates(String orderId) {
    if (_trackingOrderId == orderId) return;
    _trackingOrderId = orderId;
    _orderSub?.cancel();

    _orderSub = Supabase.instance.client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _liveStatus = data.first['status'];
              _liveProgress = (data.first['progress'] as num?)?.toDouble();
              _livePickupRiderId = data.first['pickup_rider_id'];
              _liveDeliveryRiderId = data.first['delivery_rider_id'];
            });
          }
        });
  }

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
          if (order == null &&
              state is OrdersLoaded &&
              state.activeOrders.isNotEmpty) {
            order = state.activeOrders.first;
          }
          if (order == null) {
            return AppEmptyState(
              message: 'No active order found',
              isDark: isDark,
            );
          }

          _listenToOrderUpdates(order.id);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _checkRating(context, order!, isDark);
          });

          return TrackContent(
            order: order,
            isDark: isDark,
            liveStatus: _liveStatus,
            liveProgress: _liveProgress,
            livePickupRiderId: _livePickupRiderId,
            liveDeliveryRiderId: _liveDeliveryRiderId,
          );
        },
      ),
    );
  }

  Future<void> _checkRating(
    BuildContext ctx,
    OrderEntity order,
    bool isDark,
  ) async {
    if (_ratingMem.shownForPickup && _ratingMem.shownForDelivery) return;

    final effectiveStatus = _liveStatus ?? order.status;
    final phase = effectiveStatus.phase;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    final pickupId = _livePickupRiderId ?? order.pickupRiderId ?? order.riderId;
    bool isPickupPhaseCompleted =
        phase.index >= _OrderPhase.riderHeadingToStore.index &&
        phase.index < _OrderPhase.riderComingToDeliver.index;

    if (isPickupPhaseCompleted &&
        !_ratingMem.shownForPickup &&
        pickupId != null) {
      final hasHandled = prefs.getBool('rated_pickup_${order.id}') ?? false;
      if (!hasHandled) {
        _ratingMem.shownForPickup = true;
        if (ctx.mounted)
          _showRatingSheet(ctx, order, isDark, _RatingEvent.pickup);
      } else {
        _ratingMem.shownForPickup = true;
      }
    }

    final deliveryId =
        _liveDeliveryRiderId ?? order.deliveryRiderId ?? order.riderId;
    if (phase == _OrderPhase.delivered &&
        !_ratingMem.shownForDelivery &&
        deliveryId != null) {
      final hasHandled = prefs.getBool('rated_delivery_${order.id}') ?? false;
      if (!hasHandled) {
        _ratingMem.shownForDelivery = true;
        if (ctx.mounted)
          _showRatingSheet(ctx, order, isDark, _RatingEvent.delivery);
      } else {
        _ratingMem.shownForDelivery = true;
      }
    }
  }

  void _showRatingSheet(
    BuildContext ctx,
    OrderEntity order,
    bool isDark,
    _RatingEvent evt,
  ) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetCtx) =>
          _RatingSheet(order: order, isDark: isDark, eventType: evt),
    ).then((_) async {
      final p = await SharedPreferences.getInstance();
      final key = evt == _RatingEvent.pickup
          ? 'rated_pickup_${order.id}'
          : 'rated_delivery_${order.id}';
      p.setBool(key, true);
    });
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class TrackContent extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final String? liveStatus;
  final double? liveProgress;
  final String? livePickupRiderId;
  final String? liveDeliveryRiderId;

  const TrackContent({
    super.key,
    required this.order,
    required this.isDark,
    required this.liveStatus,
    required this.liveProgress,
    required this.livePickupRiderId,
    required this.liveDeliveryRiderId,
  });

  String get _effectiveStatus => liveStatus ?? order.status;

  double get _effectiveProgress =>
      liveProgress ?? OrderStatus.getProgress(_effectiveStatus);

  String get _statusLabel => OrderStatus.format(_effectiveStatus);

  _OrderPhase get _phase => _effectiveStatus.phase;

  String? get _activeRiderId {
    if (_phase == _OrderPhase.riderComingToPickup ||
        _phase == _OrderPhase.riderHeadingToStore) {
      return livePickupRiderId ?? order.pickupRiderId ?? order.riderId;
    } else if (_phase == _OrderPhase.riderComingToDeliver ||
        _phase == _OrderPhase.delivered) {
      return liveDeliveryRiderId ?? order.deliveryRiderId ?? order.riderId;
    }
    return livePickupRiderId ?? liveDeliveryRiderId ?? order.riderId;
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _OrderPhase.delivered)
      return _DeliveredView(order: order, isDark: isDark);
    if (_phase == _OrderPhase.cancelled)
      return _CancelledView(order: order, isDark: isDark);

    Widget activePanel;
    switch (_phase) {
      case _OrderPhase.waiting:
        activePanel = _InfoPanel(
          key: const ValueKey('waiting'),
          icon: Iconsax.shop,
          color: AppColors.primary,
          title: 'Awaiting Rider',
          subtitle:
              'Your order is confirmed. A rider will be assigned shortly.',
          order: order,
          isDark: isDark,
          phase: _phase,
        );
        break;
      case _OrderPhase.riderHeadingToStore:
        activePanel = _InfoPanel(
          key: const ValueKey('transit'),
          icon: Iconsax.truck_fast,
          color: AppColors.warning,
          title: 'Heading to Store',
          subtitle:
              'The rider has picked up your items and is taking them to the laundry facility.',
          order: order,
          isDark: isDark,
          phase: _phase,
        );
        break;
      case _OrderPhase.riderComingToPickup:
      case _OrderPhase.riderComingToDeliver:
        activePanel = _MapPanel(
          key: ValueKey('map_$_effectiveStatus'),
          order: order,
          isDark: isDark,
          phase: _phase,
          activeRiderId: _activeRiderId,
        );
        break;
      case _OrderPhase.atStore:
      case _OrderPhase.cleaning:
      case _OrderPhase.ready:
        activePanel = _CleaningPanel(
          key: ValueKey('cleaning_$_effectiveStatus'),
          phase: _phase,
          order: order,
          isDark: isDark,
        );
        break;
      default:
        activePanel = const SizedBox.shrink();
    }

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
              _HeroCard(
                order: order,
                progress: _effectiveProgress,
                statusLabel: _statusLabel,
              ),
              const SizedBox(height: 18),
              _PhaseBanner(phase: _phase, isDark: isDark),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: activePanel,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final OrderEntity order;
  final double progress;
  final String statusLabel;

  const _HeroCard({
    required this.order,
    required this.progress,
    required this.statusLabel,
  });

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
                    '${(progress * 100).toInt()}%',
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
                tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: v,
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
              _HeaderInfo(label: 'Status', value: statusLabel),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Phase Banner ─────────────────────────────────────────────────────────────

class _PhaseBanner extends StatelessWidget {
  final _OrderPhase phase;
  final bool isDark;

  const _PhaseBanner({required this.phase, required this.isDark});

  _BannerCfg get _cfg {
    switch (phase) {
      case _OrderPhase.waiting:
        return const _BannerCfg(
          Iconsax.clock,
          AppColors.warning,
          'Preparing Order',
          'We are processing your order details.',
        );
      case _OrderPhase.riderComingToPickup:
        return const _BannerCfg(
          Iconsax.car,
          AppColors.primary,
          'Rider Dispatched',
          'A rider is on their way to pick up your laundry.',
        );
      case _OrderPhase.riderHeadingToStore:
        return const _BannerCfg(
          Iconsax.truck_fast,
          AppColors.warning,
          'Heading to Store',
          'Rider is taking your items to the facility.',
        );
      case _OrderPhase.atStore:
        return const _BannerCfg(
          Iconsax.shop,
          Color(0xFF8B5CF6),
          'Items at the Store',
          'Your laundry has safely arrived.',
        );
      case _OrderPhase.cleaning:
        return const _BannerCfg(
          Iconsax.refresh,
          AppColors.info,
          'Cleaning in Progress',
          'Our team is washing & drying your laundry.',
        );
      case _OrderPhase.ready:
        return const _BannerCfg(
          Iconsax.box_1,
          AppColors.success,
          'Packed & Ready',
          'Your laundry is fresh and ready to be dispatched.',
        );
      case _OrderPhase.riderComingToDeliver:
        return const _BannerCfg(
          Iconsax.truck_fast,
          Color(0xFF8B5CF6),
          'On the Way',
          'Your fresh laundry is headed to your address.',
        );
      default:
        return const _BannerCfg(
          Iconsax.info_circle,
          AppColors.primary,
          'Processing',
          'Your order is being handled.',
        );
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: c.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  c.subtitle,
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
        ],
      ),
    );
  }
}

class _BannerCfg {
  final IconData icon;
  final Color color;
  final String title, subtitle;

  const _BannerCfg(this.icon, this.color, this.title, this.subtitle);
}

// ─── Info Panel ───────────────────────────────────────────────────────────────

class _InfoPanel extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;

  const _InfoPanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.isDark,
    required this.phase,
  });

  @override
  State<_InfoPanel> createState() => _InfoPanelState();
}

class _InfoPanelState extends State<_InfoPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : widget.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : widget.color.withOpacity(0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + 0.1 * _pulseCtrl.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(0.15),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _OrderDetailsCard(
          order: widget.order,
          isDark: widget.isDark,
          phase: widget.phase,
        ),
      ],
    );
  }
}

// ─── Cleaning Panel ──────────────────────────────────────────────────────────

class _CleaningPanel extends StatefulWidget {
  final _OrderPhase phase;
  final OrderEntity order;
  final bool isDark;

  const _CleaningPanel({
    super.key,
    required this.phase,
    required this.order,
    required this.isDark,
  });

  @override
  State<_CleaningPanel> createState() => _CleaningPanelState();
}

class _CleaningPanelState extends State<_CleaningPanel>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl, _pulseCtrl, _bubbleCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      children: [
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
                  : AppColors.primary.withOpacity(0.15),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 0.95 + 0.1 * _pulseCtrl.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, __) => Transform.rotate(
                  angle: _spinCtrl.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(90, 90),
                    painter: _ArcPainter(),
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradient,
                ),
                child: Icon(
                  widget.phase == _OrderPhase.atStore
                      ? Iconsax.shop
                      : Iconsax.refresh,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              ..._bubbles(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CleaningSteps(phase: widget.phase, isDark: widget.isDark),
        const SizedBox(height: 20),
        _OrderDetailsCard(
          order: widget.order,
          isDark: widget.isDark,
          phase: widget.phase,
        ),
      ],
    );
  }

  List<Widget> _bubbles() {
    const positions = [
      Offset(-80, -60),
      Offset(75, -55),
      Offset(-65, 55),
      Offset(72, 60),
      Offset(-10, -88),
      Offset(5, 84),
    ];
    return positions.asMap().entries.map((e) {
      final p = e.key / positions.length;
      return AnimatedBuilder(
        animation: _bubbleCtrl,
        builder: (_, __) {
          final t = (_bubbleCtrl.value + p) % 1.0;
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
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          const LinearGradient(
            colors: [AppColors.primary, Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width / 2,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter _) => false;
}

class _CleaningSteps extends StatelessWidget {
  final _OrderPhase phase;
  final bool isDark;

  const _CleaningSteps({required this.phase, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepDef(
        icon: Iconsax.shop,
        label: 'Received',
        done: phase == _OrderPhase.cleaning || phase == _OrderPhase.ready,
        active: phase == _OrderPhase.atStore,
      ),
      _StepDef(
        icon: Iconsax.drop,
        label: 'Washing',
        done: phase == _OrderPhase.ready,
        active: phase == _OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.flash_1,
        label: 'Drying',
        done: phase == _OrderPhase.ready,
        active: phase == _OrderPhase.cleaning,
      ),
      _StepDef(
        icon: Iconsax.box_1,
        label: 'Ready',
        done: phase == _OrderPhase.ready,
        active: phase == _OrderPhase.ready,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cleaning Process',
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: steps.asMap().entries.map((e) {
              final s = e.value;
              final isLast = e.key == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
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
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
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
                          Text(
                            s.label,
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepDef {
  final IconData icon;
  final String label;
  final bool done, active;

  const _StepDef({
    required this.icon,
    required this.label,
    this.done = false,
    this.active = false,
  });
}

// ─── Map Panel ───────────────────────────────────────────────────────────────

class _MapPanel extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;
  final String? activeRiderId;

  const _MapPanel({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
    this.activeRiderId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapView(
          order: order,
          isDark: isDark,
          phase: phase,
          activeRiderId: activeRiderId,
        ),
        const SizedBox(height: 18),
        _OrderDetailsCard(order: order, isDark: isDark, phase: phase),
      ],
    );
  }
}

// ─── Shared Dynamic Details Card ─────────────────────────────────────────────

class _OrderDetailsCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;

  const _OrderDetailsCard({
    required this.order,
    required this.isDark,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isDeliveryTarget = phase.index >= _OrderPhase.atStore.index;
    final title = isDeliveryTarget ? 'Delivery Details' : 'Pickup Details';
    final targetAddress = isDeliveryTarget
        ? (order.deliveryAddress ?? order.pickupAddress)
        : order.pickupAddress;
    final dateLabel = isDeliveryTarget
        ? 'Estimated Delivery'
        : 'Scheduled Pickup';
    final dateValue = isDeliveryTarget ? order.deliveryDate : order.pickupDate;
    final timeValue = isDeliveryTarget ? order.deliveryTime : order.pickupTime;
    final iconColor = isDeliveryTarget ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.location_on_rounded,
            color: iconColor,
            title: 'Address',
            sub: targetAddress,
            isDark: isDark,
          ),
          _InfoTile(
            icon: Iconsax.timer_1,
            color: AppColors.warning,
            title: dateLabel,
            sub: dateValue != null
                ? '${dateValue.day}/${dateValue.month}/${dateValue.year}${timeValue != null ? " at $timeValue" : ""}'
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
    );
  }
}

// ─── Delivered view ──────────────────────────────────────────────────────────

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
  late final Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.success, Color(0xFF059669)],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Delivered!',
                style: GoogleFonts.alexandria(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your laundry has been delivered.\nThank you for using EzeeWash!',
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  color: widget.isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.tag_rounded,
                      label: 'Order',
                      value: '#${widget.order.orderNumber}',
                      isDark: widget.isDark,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      icon: Iconsax.drop,
                      label: 'Service',
                      value: widget.order.serviceName,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      icon: Iconsax.money,
                      label: 'Total Paid',
                      value: '৳${widget.order.totalPrice.toStringAsFixed(0)}',
                      isDark: widget.isDark,
                      highlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Order Cancelled',
            style: GoogleFonts.alexandria(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Go Back',
              style: GoogleFonts.alexandria(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map view (CRITICAL FIXES) ───────────────────────────────────────────────

class MapView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;
  final String? activeRiderId;

  const MapView({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
    this.activeRiderId,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _cc = Completer();
  GoogleMapController? _mapCtrl;
  LatLng? _customerLoc, _riderPos;
  bool _loading = true, _denied = false;
  StreamSubscription? _sub;
  Map<String, dynamic>? _riderRow;

  static const LatLng _dhaka = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    if (widget.order.riderLat != null && widget.order.riderLng != null) {
      _riderPos = LatLng(widget.order.riderLat!, widget.order.riderLng!);
    }
    _init();
  }

  @override
  void didUpdateWidget(MapView old) {
    super.didUpdateWidget(old);
    if (old.activeRiderId != widget.activeRiderId) _listenRider();
    if (old.phase != widget.phase) _fit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapCtrl = null; // Important: Clear ref
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final addr = widget.phase == _OrderPhase.riderComingToDeliver
          ? (widget.order.deliveryAddress ?? widget.order.pickupAddress)
          : widget.order.pickupAddress;
      if (addr.isNotEmpty) {
        final locs = await locationFromAddress(addr);
        if (locs.isNotEmpty)
          _customerLoc = LatLng(locs.first.latitude, locs.first.longitude);
      }
    } catch (_) {}

    if (!mounted) return;

    if (_customerLoc == null) {
      try {
        final svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (svcEnabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied)
            perm = await Geolocator.requestPermission();
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition();
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
    _sub?.cancel();
    if (widget.activeRiderId == null) return;
    _sub = Supabase.instance.client
        .from('riders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.activeRiderId!)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final row = data.first;
            final lat = (row['current_lat'] as num?)?.toDouble();
            final lng = (row['current_lng'] as num?)?.toDouble();
            setState(() {
              _riderRow = row;
              if (lat != null && lng != null) _riderPos = LatLng(lat, lng);
            });
            _fit();
          }
        });
  }

  Future<void> _fit() async {
    if (_customerLoc == null) return;
    final ctrl = await _cc.future;

    if (!mounted || _mapCtrl == null) return; // FIX: Async mounted guard

    try {
      if (_riderPos != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            math.min(_customerLoc!.latitude, _riderPos!.latitude),
            math.min(_customerLoc!.longitude, _riderPos!.longitude),
          ),
          northeast: LatLng(
            math.max(_customerLoc!.latitude, _riderPos!.latitude),
            math.max(_customerLoc!.longitude, _riderPos!.longitude),
          ),
        );
        await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
      } else {
        await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_customerLoc!, 15));
      }
    } catch (e) {
      debugPrint("Map animation failed: $e");
    }
  }

  Set<Marker> get _markers => {
    if (_customerLoc != null)
      Marker(
        markerId: const MarkerId('customer'),
        position: _customerLoc!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    if (_riderPos != null)
      Marker(
        markerId: const MarkerId('rider'),
        position: _riderPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: _onRiderMarkerTap,
      ),
  };

  Set<Polyline> get _polylines => (_customerLoc == null || _riderPos == null)
      ? {}
      : {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_riderPos!, _customerLoc!],
            color: AppColors.primary,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };

  void _onRiderMarkerTap() {
    if (_riderRow == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RiderInfoSheet(
        order: widget.order,
        isDark: widget.isDark,
        phase: widget.phase,
        initialRiderRow: _riderRow!,
        initialRiderPos: _riderPos,
        customerLoc: _customerLoc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _customerLoc ?? _dhaka,
                  zoom: 14,
                ),
                onMapCreated: (ctrl) {
                  if (!_cc.isCompleted) _cc.complete(ctrl);
                  _mapCtrl = ctrl;
                  if (widget.isDark)
                    ctrl.setMapStyle(AppConstants.darkMapStyle);
                  _fit();
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                gestureRecognizers: {
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
              ),
      ),
    );
  }
}

// ─── Utility Widgets ─────────────────────────────────────────────────────────

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
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark, highlight;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: highlight ? AppColors.success : Colors.grey),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.alexandria(
          fontSize: highlight ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: highlight
              ? AppColors.success
              : (isDark ? Colors.white : AppColors.lightText),
        ),
      ),
    ],
  );
}

// ─── Rider Info Sheet ────────────────────────────────────────────────────────

class _RiderInfoSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;
  final Map<String, dynamic> initialRiderRow;
  final LatLng? initialRiderPos, customerLoc;

  const _RiderInfoSheet({
    required this.order,
    required this.isDark,
    required this.phase,
    required this.initialRiderRow,
    this.initialRiderPos,
    this.customerLoc,
  });

  @override
  State<_RiderInfoSheet> createState() => _RiderInfoSheetState();
}

class _RiderInfoSheetState extends State<_RiderInfoSheet> {
  late Map<String, dynamic> _riderRow;
  LatLng? _riderPos;
  double? _distanceKm;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _riderRow = widget.initialRiderRow;
    _riderPos = widget.initialRiderPos;
    _listenToRider();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listenToRider() {
    _sub = Supabase.instance.client
        .from('riders')
        .stream(primaryKey: ['id'])
        .eq('id', _riderRow['id'])
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final row = data.first;
            final lat = (row['current_lat'] as num?)?.toDouble();
            final lng = (row['current_lng'] as num?)?.toDouble();
            setState(() {
              _riderRow = row;
              if (lat != null && lng != null) {
                _riderPos = LatLng(lat, lng);
                if (widget.customerLoc != null)
                  _distanceKm =
                      Geolocator.distanceBetween(
                        lat,
                        lng,
                        widget.customerLoc!.latitude,
                        widget.customerLoc!.longitude,
                      ) /
                      1000;
              }
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _riderRow['full_name'] ?? 'Rider',
            style: GoogleFonts.alexandria(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Rating',
                  value: '${_riderRow['rating'] ?? 5.0}',
                  icon: Icons.star,
                  color: Colors.orange,
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  label: 'Distance',
                  value: _distanceKm != null
                      ? '${_distanceKm!.toStringAsFixed(1)} km'
                      : '--',
                  icon: Icons.map,
                  color: AppColors.primary,
                  isDark: widget.isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.call,
                  label: 'Call',
                  color: AppColors.success,
                  isDark: widget.isDark,
                  enabled: true,
                  onTap: () async =>
                      launchUrl(Uri.parse('tel:${_riderRow['phone']}')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.chat,
                  label: 'Message',
                  color: AppColors.primary,
                  isDark: widget.isDark,
                  enabled: true,
                  onTap: () async =>
                      launchUrl(Uri.parse('sms:${_riderRow['phone']}')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}

class _SheetActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark, enabled;
  final VoidCallback onTap;

  const _SheetActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ─── Rating Sheet ────────────────────────────────────────────────────────────

class _RatingSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _RatingEvent eventType;

  const _RatingSheet({
    required this.order,
    required this.isDark,
    required this.eventType,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  bool _loading = false, _submitted = false;
  String _comment = '';

  Future<void> _submit() async {
    if (_stars == 0) return;
    setState(() => _loading = true);
    try {
      final riderId = widget.eventType == _RatingEvent.pickup
          ? (widget.order.pickupRiderId ?? widget.order.riderId)
          : (widget.order.deliveryRiderId ?? widget.order.riderId);
      await Supabase.instance.client.from('rider_ratings').upsert({
        'order_id': widget.order.id,
        'rider_id': riderId,
        'stars': _stars,
        'comment': _comment,
        'rating_type': widget.eventType.name,
      });
      if (mounted)
        setState(() {
          _loading = false;
          _submitted = true;
        });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _submitted
          ? const Center(child: Text('Thank you for your feedback!'))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rate your experience',
                  style: GoogleFonts.alexandria(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < _stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => _stars = i + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (v) => _comment = v,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _stars > 0 && !_loading ? _submit : null,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
    );
  }
}
