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
  waiting, // pending / confirmed -> No map. Waiting for rider.
  riderComingToPickup, // assign_pickup -> MAP SHOWN. Rider coming to user.
  riderHeadingToStore, // picked_up -> No map. Rider going away to laundry.
  atStore, // dropped / received -> No map. At facility.
  cleaning, // in_process -> No map. Washing.
  ready, // ready -> No map. Packed.
  riderComingToDeliver, // out_for_delivery -> MAP SHOWN. Rider coming to user.
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

// ─── Rating helpers ──────────────────────────────────────────────────────────

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

  // ── Real-Time Order State ──
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

  // Listens directly to the DB to change the UI instantly when the admin updates it
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
          if (order == null)
            return AppEmptyState(
              message: 'No active order found',
              isDark: isDark,
            );

          // Activate real-time listener for this specific order
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

    final pickupId = _livePickupRiderId ?? order.pickupRiderId ?? order.riderId;
    if (phase == _OrderPhase.atStore &&
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
    final safeCtx = context;
    if (!safeCtx.mounted) return;
    showModalBottomSheet(
      context: safeCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetCtx) =>
          _RatingSheet(order: order, isDark: isDark, eventType: evt),
    ).then((_) {
      SharedPreferences.getInstance().then((p) {
        final key = evt == _RatingEvent.pickup
            ? 'rated_pickup_${order.id}'
            : 'rated_delivery_${order.id}';
        p.setBool(key, true);
      });
    });
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class TrackContent extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  // Real-time overrides from parent stream
  final String? liveStatus;
  final double? liveProgress;
  final String? livePickupRiderId;
  final String? liveDeliveryRiderId;

  const TrackContent({
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

// ─── Hero card ────────────────────────────────────────────────────────────────

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

// ─── Phase banner ─────────────────────────────────────────────────────────────

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

// ─── Info panel (For waiting & transit) ───────────────────────────────────────

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

// ─── Cleaning panel ───────────────────────────────────────────────────────────

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
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _bubbleCtrl;

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
                animation: _pulseCtrl,
                builder: (_, __) => Transform.scale(
                  scale: 1.0 + 0.07 * math.sin(_pulseCtrl.value * math.pi),
                  child: Container(
                    width: 115,
                    height: 115,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.09),
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

// ─── Map panel ────────────────────────────────────────────────────────────────

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
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF059669)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
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
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      'Order Delivered!',
                      style: GoogleFonts.alexandria(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.lightText,
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
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
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
                      color: AppColors.success.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
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
                        icon: Iconsax.shop,
                        label: 'Store',
                        value: widget.order.storeName,
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        ),
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
            const SizedBox(height: 8),
            Text(
              'This order has been cancelled.',
              style: GoogleFonts.alexandria(
                fontSize: 13,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 40,
                ),
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
      ),
    );
  }
}

// ─── Map view (Real-Time Rider Locations) ─────────────────────────────────────

class MapView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;
  final String? activeRiderId;

  const MapView({
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
  LatLng? _customerLoc;
  LatLng? _riderPos;
  bool _loading = true;
  bool _denied = false;
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
    if (old.activeRiderId != widget.activeRiderId) {
      _listenRider();
    }
    if (old.phase != widget.phase) _fit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final addr = widget.phase == _OrderPhase.riderComingToDeliver
          ? (widget.order.deliveryAddress ?? widget.order.pickupAddress)
          : widget.order.pickupAddress;

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
          if (perm == LocationPermission.denied)
            perm = await Geolocator.requestPermission();
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
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

  // Real-Time stream from `riders` table to automatically get live coordinates
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
              if (lat != null && lng != null) {
                _riderPos = LatLng(lat, lng);
              }
            });
            _fit();
          }
        });
  }

  void _onRiderMarkerTap() {
    if (_riderRow == null) return;
    final distKm = (_customerLoc != null && _riderPos != null)
        ? Geolocator.distanceBetween(
                _riderPos!.latitude,
                _riderPos!.longitude,
                _customerLoc!.latitude,
                _customerLoc!.longitude,
              ) /
              1000
        : null;

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
        initialDistanceKm: distKm,
        customerLoc:
            _customerLoc, // Enables real-time updates inside the sheet!
      ),
    );
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
          LatLngBounds(southwest: sw, northeast: ne),
          70,
        ),
      );
    } else {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_customerLoc!, 15));
    }
  }

  Set<Marker> get _markers {
    final m = <Marker>{};
    if (_customerLoc != null) {
      m.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLoc!,
          infoWindow: InfoWindow(
            title: widget.phase == _OrderPhase.riderComingToDeliver
                ? 'Your Address (Delivery)'
                : 'Your Address (Pickup)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    if (_riderPos != null) {
      m.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: _riderPos!,
          infoWindow: InfoWindow(
            title: widget.phase == _OrderPhase.riderComingToDeliver
                ? 'Rider • Delivering'
                : 'Rider • Coming to Pickup',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: _onRiderMarkerTap,
        ),
      );
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
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: widget.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
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
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        gestureRecognizers: {
                          Factory<EagerGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
              ),
            ),
          ),
          if (_riderPos != null)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Tap rider',
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.phase == _OrderPhase.riderComingToDeliver
                        ? Iconsax.truck_fast
                        : Iconsax.car,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.phase == _OrderPhase.riderComingToDeliver
                        ? 'Rider delivering'
                        : 'Rider picking up',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _dhaka, zoom: 12),
          onMapCreated: (ctrl) {
            if (!_cc.isCompleted) _cc.complete(ctrl);
            _mapCtrl = ctrl;
            if (widget.isDark) ctrl.setMapStyle(AppConstants.darkMapStyle);
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          gestureRecognizers: {
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
        Positioned.fill(
          child: Container(
            color: widget.isDark
                ? Colors.black.withOpacity(0.55)
                : Colors.white.withOpacity(0.72),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Locating address…',
                    style: GoogleFonts.alexandria(
                      fontSize: 13,
                      color: widget.isDark
                          ? Colors.white70
                          : AppColors.lightSubtext,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deniedOverlay() => Stack(
    children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(target: _dhaka, zoom: 12),
        onMapCreated: (ctrl) {
          if (!_cc.isCompleted) _cc.complete(ctrl);
          _mapCtrl = ctrl;
          if (widget.isDark) ctrl.setMapStyle(AppConstants.darkMapStyle);
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        gestureRecognizers: {
          Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
      Positioned(
        top: 12,
        left: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xCC1A2540)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_searching_rounded,
                size: 16,
                color: widget.isDark ? Colors.white70 : AppColors.lightSubtext,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not resolve delivery address',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: widget.isDark
                        ? Colors.white70
                        : AppColors.lightSubtext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
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
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.success.withOpacity(0.12)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: highlight
              ? AppColors.success
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ),
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

// ─── Real-Time Rider info bottom sheet ────────────────────────────────────────

class _RiderInfoSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final _OrderPhase phase;

  // Passed from MapView to initiate state
  final Map<String, dynamic> initialRiderRow;
  final LatLng? initialRiderPos;
  final double? initialDistanceKm;

  // Target location (customer address) used for live distance recalculation
  final LatLng? customerLoc;

  const _RiderInfoSheet({
    required this.order,
    required this.isDark,
    required this.phase,
    required this.initialRiderRow,
    this.initialRiderPos,
    this.initialDistanceKm,
    this.customerLoc,
  });

  @override
  State<_RiderInfoSheet> createState() => _RiderInfoSheetState();
}

class _RiderInfoSheetState extends State<_RiderInfoSheet> {
  late Map<String, dynamic> _riderRow;
  late LatLng? _riderPos;
  late double? _distanceKm;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _riderRow = widget.initialRiderRow;
    _riderPos = widget.initialRiderPos;
    _distanceKm = widget.initialDistanceKm;
    _listenToRider();
  }

  void _listenToRider() {
    final riderId = _riderRow['id'] as String?;
    if (riderId == null) return;

    _sub = Supabase.instance.client
        .from('riders')
        .stream(primaryKey: ['id'])
        .eq('id', riderId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            final row = data.first;
            final lat = (row['current_lat'] as num?)?.toDouble();
            final lng = (row['current_lng'] as num?)?.toDouble();

            LatLng? newPos;
            double? newDist = _distanceKm;

            if (lat != null && lng != null) {
              newPos = LatLng(lat, lng);
              if (widget.customerLoc != null) {
                newDist =
                    Geolocator.distanceBetween(
                      lat,
                      lng,
                      widget.customerLoc!.latitude,
                      widget.customerLoc!.longitude,
                    ) /
                    1000;
              }
            }

            setState(() {
              _riderRow = row;
              _riderPos = newPos;
              _distanceKm = newDist;
            });
          }
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String get _name => _riderRow['full_name'] as String? ?? 'Your Rider';

  String? get _photo => _riderRow['avatar_url'] as String?;

  String get _phone => _riderRow['phone'] as String? ?? '';

  double get _rating => (_riderRow['rating'] as num?)?.toDouble() ?? 5.0;

  bool get _online => _riderRow['is_online'] as bool? ?? false;

  int get _trips => _riderRow['total_trips'] as int? ?? 0;

  String get _vtype => _riderRow['vehicle_type'] as String? ?? 'motorcycle';

  String? get _plate => _riderRow['vehicle_plate'] as String?;

  String get _distLabel {
    if (_distanceKm == null) return '—';
    if (_distanceKm! < 1) return '${(_distanceKm! * 1000).toInt()} m';
    return '${_distanceKm!.toStringAsFixed(1)} km';
  }

  String get _etaLabel {
    if (_distanceKm == null) return '—';
    final m = ((_distanceKm! / 25) * 60).ceil();
    return m < 2 ? '< 1 min' : '$m min';
  }

  String get _latLngLabel {
    if (_riderPos == null) return '—';
    return '${_riderPos!.latitude.toStringAsFixed(5)}, ${_riderPos!.longitude.toStringAsFixed(5)}';
  }

  IconData _vIcon() {
    switch (_vtype) {
      case 'bicycle':
        return Icons.pedal_bike_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.phase == _OrderPhase.riderComingToPickup;
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _photo != null
                      ? Image.network(
                          _photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fb(),
                        )
                      : _fb(),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _online ? AppColors.success : Colors.grey.shade400,
                  border: Border.all(
                    color: widget.isDark ? AppColors.darkSurface : Colors.white,
                    width: 2.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _name,
            style: GoogleFonts.alexandria(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(widget.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPickup ? 'Picking up your order' : 'Delivering your order',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatBox(
                label: 'Rating',
                value: _rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
                isDark: widget.isDark,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Trips',
                value: '$_trips',
                icon: Icons.route_rounded,
                color: AppColors.primary,
                isDark: widget.isDark,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'ETA',
                value: _etaLabel,
                icon: Icons.access_time_rounded,
                color: AppColors.success,
                isDark: widget.isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetInfoRow(
            icon: Icons.near_me_rounded,
            color: AppColors.primary,
            title: 'Distance',
            value: _distLabel,
            isDark: widget.isDark,
          ),
          _SheetInfoRow(
            icon: _vIcon(),
            color: const Color(0xFF8B5CF6),
            title: 'Vehicle',
            value:
                '${_vtype[0].toUpperCase()}${_vtype.substring(1)}${_plate != null ? "  •  $_plate" : ""}',
            isDark: widget.isDark,
          ),
          _SheetInfoRow(
            icon: Icons.location_on_rounded,
            color: AppColors.warning,
            title: 'Current Location',
            value: _latLngLabel,
            isDark: widget.isDark,
          ),
          _SheetInfoRow(
            icon: Icons.circle,
            color: _online ? AppColors.success : Colors.grey,
            title: 'Status',
            value: _online ? 'Online' : 'Offline',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.call_rounded,
                  label: 'Call Rider',
                  color: AppColors.success,
                  isDark: widget.isDark,
                  enabled: _phone.isNotEmpty,
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri phoneUri = Uri(scheme: 'tel', path: _phone);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open dialer',
                            style: GoogleFonts.alexandria(fontSize: 13),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  color: AppColors.primary,
                  isDark: widget.isDark,
                  enabled: _phone.isNotEmpty,
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri smsUri = Uri(scheme: 'sms', path: _phone);
                    if (await canLaunchUrl(smsUri)) {
                      await launchUrl(smsUri);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not open messaging app',
                            style: GoogleFonts.alexandria(fontSize: 13),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fb() => Container(
    color: AppColors.primary.withOpacity(0.12),
    alignment: Alignment.center,
    child: Text(
      _name.isNotEmpty ? _name[0].toUpperCase() : 'R',
      style: GoogleFonts.alexandria(
        color: AppColors.primary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
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
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.alexandria(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 10,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, value;
  final bool isDark;

  const _SheetInfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
                value,
                style: GoogleFonts.alexandria(
                  fontSize: 14,
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: enabled
            ? color.withOpacity(isDark ? 0.18 : 0.1)
            : (isDark ? Colors.white10 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? color.withOpacity(0.3)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled
                ? color
                : (isDark ? Colors.white38 : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? color
                  : (isDark ? Colors.white38 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Rating sheet ─────────────────────────────────────────────────────────────

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

class _RatingSheetState extends State<_RatingSheet>
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

  String? get _targetRiderId => widget.eventType == _RatingEvent.pickup
      ? (widget.order.pickupRiderId ?? widget.order.riderId)
      : (widget.order.deliveryRiderId ?? widget.order.riderId);

  Future<void> _markAsHandled() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.eventType == _RatingEvent.pickup
        ? 'rated_pickup_${widget.order.id}'
        : 'rated_delivery_${widget.order.id}';
    await prefs.setBool(key, true);
  }

  Future<void> _submit() async {
    if (_stars == 0) return;
    final client = Supabase.instance.client;
    final riderId = _targetRiderId;
    final userId = client.auth.currentUser?.id;

    if (riderId == null || userId == null) return;
    setState(() => _loading = true);

    try {
      try {
        final res = await client
            .from('riders')
            .select('rating, total_trips')
            .eq('id', riderId)
            .maybeSingle();
        if (res != null) {
          final cur = (res['rating'] as num?)?.toDouble() ?? 5.0;
          final trips = (res['total_trips'] as int?) ?? 0;
          final newR = double.parse(
            ((cur * trips + _stars) / (trips + 1)).toStringAsFixed(2),
          );
          await client
              .from('riders')
              .update({'rating': newR, 'total_trips': trips + 1})
              .eq('id', riderId);
        }
      } catch (_) {}

      await client.from('rider_ratings').upsert({
        'order_id': widget.order.id,
        'rider_id': riderId,
        'user_id': userId,
        'rating_type': widget.eventType == _RatingEvent.pickup
            ? 'pickup'
            : 'delivery',
        'stars': _stars.toDouble(),
        'comment': _comment.trim().isEmpty ? null : _comment.trim(),
      }, onConflict: 'order_id,rating_type');
      await _markAsHandled();

      if (!mounted) return;
      setState(() {
        _submitted = true;
        _loading = false;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: _submitted ? _success() : _form(),
      ),
    );
  }

  Widget _form() {
    final name = widget.order.riderName ?? 'Your Rider';
    final photo = widget.order.riderAvatarUrl;
    return Column(
      key: const ValueKey('form_ui'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 2.5,
            ),
          ),
          child: ClipOval(
            child: photo != null
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fb(name),
                  )
                : _fb(name),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.eventType == _RatingEvent.pickup
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final s = i + 1;
            return AnimatedBuilder(
              animation: _starAnims[i],
              builder: (_, __) => Transform.scale(
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
                  style: GoogleFonts.alexandria(fontWeight: FontWeight.w600),
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

  Widget _success() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        key: const ValueKey('success_ui'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
            'Thank you for sharing your experience.\nYour feedback helps us provide a better service.',
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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

  Widget _fb(String name) => Container(
    color: AppColors.primary.withOpacity(0.12),
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
