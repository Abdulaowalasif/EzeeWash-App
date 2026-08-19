// lib/features/orders/presentation/screens/track_order_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/order_status.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../bloc/rider_tracking_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/usecases/orders_usecase.dart';
import '../widgets/track_order/track_order_cleaning_panel.dart';
import '../widgets/track_order/track_order_details_card.dart';
import '../widgets/track_order/track_order_hero_card.dart';
import '../widgets/track_order/track_order_info_panel.dart';
import '../widgets/track_order/track_order_map_view.dart';
import '../widgets/track_order/track_order_rating_sheet.dart';

enum OrderPhase {
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

extension OrderPhaseX on String {
  OrderPhase get phase {
    final s = OrderStatus.getDisplayStatus(this);
    switch (s) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return OrderPhase.waiting;
      case OrderStatus.assignPickup:
        return OrderPhase.riderComingToPickup;
      case OrderStatus.pickedUp:
        return OrderPhase.riderHeadingToStore;
      case OrderStatus.dropped:
      case OrderStatus.received:
        return OrderPhase.atStore;
      case OrderStatus.inProcess:
        return OrderPhase.cleaning;
      case OrderStatus.ready:
        return OrderPhase.ready;
      case OrderStatus.outForDelivery:
        return OrderPhase.riderComingToDeliver;
      case OrderStatus.delivered:
        return OrderPhase.delivered;
      case OrderStatus.cancelled:
        return OrderPhase.cancelled;
      default:
        return OrderPhase.waiting;
    }
  }
}

enum RatingEvent { pickup, delivery }

class _RatingMemory {
  bool shownForPickup = false;
  bool shownForDelivery = false;
}

class TrackOrderScreen extends StatefulWidget {
  final String? orderId;

  const TrackOrderScreen({super.key, this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final _ratingMem = _RatingMemory();
  bool _isSheetVisible = false;

  OrderEntity? _specificOrder;
  bool _isLoadingSpecificOrder = false;
  bool _hasAttemptedFetch = false;

  void _fetchSpecificOrder(String orderId) async {
    if (_isLoadingSpecificOrder || _specificOrder != null || _hasAttemptedFetch) return;
    if (!mounted) return;
    setState(() {
      _isLoadingSpecificOrder = true;
      _hasAttemptedFetch = true;
    });

    final getOrder = sl<GetOrderByIdUseCase>();
    final result = await getOrder(OrderIdParams(orderId));

    if (mounted) {
      setState(() {
        _isLoadingSpecificOrder = false;
        result.fold((failure) {}, (order) => _specificOrder = order);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkRating(
    BuildContext ctx,
    OrderEntity order,
    bool isDark,
  ) async {
    if (_isSheetVisible ||
        (_ratingMem.shownForPickup && _ratingMem.shownForDelivery)) {
      return;
    }

    final effectiveStatus = order.status;
    final phase = effectiveStatus.phase;
    final prefs = await SharedPreferences.getInstance();

    final pickupId = order.pickupRiderId ?? order.riderId;
    final isPickupDone =
        phase.index >= OrderPhase.riderHeadingToStore.index &&
        phase != OrderPhase.cancelled;

    if (isPickupDone && !_ratingMem.shownForPickup && pickupId != null) {
      final handled = prefs.getBool('rated_pickup_${order.id}') ?? false;
      if (!handled) {
        _isSheetVisible = true;
        _ratingMem.shownForPickup = true;
        if (ctx.mounted) {
          await _showRatingSheet(ctx, order, isDark, RatingEvent.pickup);
          _isSheetVisible = false;
          if (ctx.mounted) _checkRating(ctx, order, isDark);
          return;
        }
      } else {
        _ratingMem.shownForPickup = true;
      }
    }

    final deliveryId = order.deliveryRiderId ?? order.riderId;
    if (phase == OrderPhase.delivered &&
        !_ratingMem.shownForDelivery &&
        deliveryId != null) {
      final handled = prefs.getBool('rated_delivery_${order.id}') ?? false;
      if (!handled) {
        _isSheetVisible = true;
        _ratingMem.shownForDelivery = true;
        if (ctx.mounted) {
          await _showRatingSheet(ctx, order, isDark, RatingEvent.delivery);
          _isSheetVisible = false;
        }
      } else {
        _ratingMem.shownForDelivery = true;
      }
    }
  }

  Future<void> _showRatingSheet(
    BuildContext ctx,
    OrderEntity order,
    bool isDark,
    RatingEvent evt,
  ) async {
    if (!ctx.mounted) return;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (_) =>
          TrackOrderRatingSheet(order: order, isDark: isDark, eventType: evt),
    );

    final p = await SharedPreferences.getInstance();
    final key = evt == RatingEvent.pickup
        ? 'rated_pickup_${order.id}'
        : 'rated_delivery_${order.id}';
    await p.setBool(key, true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: const GradientAppBar(title: 'Track Order'),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          OrderEntity? order;

          if (widget.orderId != null) {
            // 1. Try to find it in the bloc's loaded list
            if (state is OrdersLoaded) {
              try {
                order = state.orders.firstWhere((o) => o.id == widget.orderId);
              } catch (_) {
                try {
                  order = state.orders.firstWhere((o) => o.groupId == widget.orderId);
                } catch (_) {}
              }
            }

            // 2. Try the local fetched copy
            order ??= _specificOrder;

            // 3. If still null, trigger a fetch if we haven't already
            if (order == null) {
              if (state is! OrdersLoading && !_isLoadingSpecificOrder && !_hasAttemptedFetch) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _fetchSpecificOrder(widget.orderId!);
                });
              }

              if (_isLoadingSpecificOrder || state is OrdersLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
            }
          } else {
            // No specific order ID provided. Default to most recent active order.
            if (state is OrdersLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is OrdersLoaded && state.activeOrders.isNotEmpty) {
              order = state.activeOrders.first;
            }
          }

          if (order == null) {
            return AppEmptyState(
              message: widget.orderId != null
                  ? 'Order not found'
                  : 'No active order found',
              isDark: isDark,
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _checkRating(context, order!, isDark);
          });

          List<OrderEntity> groupOrders = [order!];
          if (order.groupId != null && order.groupId!.isNotEmpty && state is OrdersLoaded) {
            groupOrders = state.orders.where((o) => o.groupId == order!.groupId).toList();
            groupOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          return _TrackContent(order: order, groupOrders: groupOrders, isDark: isDark);
        },
      ),
    );
  }
}

class _TrackContent extends StatelessWidget {
  final OrderEntity order;
  final List<OrderEntity> groupOrders;
  final bool isDark;

  const _TrackContent({required this.order, required this.groupOrders, required this.isDark});

  String get _status => order.status;

  double get _progress => OrderStatus.getProgress(_status);

  String get _statusLabel => OrderStatus.format(_status);

  OrderPhase get _phase => _status.phase;

  String? get _activeRiderId {
    if (_phase == OrderPhase.riderComingToPickup ||
        _phase == OrderPhase.riderHeadingToStore) {
      return order.pickupRiderId ?? order.riderId;
    } else if (_phase == OrderPhase.riderComingToDeliver ||
        _phase == OrderPhase.delivered) {
      return order.deliveryRiderId ?? order.riderId;
    }
    return order.riderId;
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == OrderPhase.delivered) {
      return _DeliveredView(order: order, isDark: isDark);
    }
    if (_phase == OrderPhase.cancelled) {
      return _CancelledView(order: order, isDark: isDark);
    }

    Widget activePanel;
    switch (_phase) {
      case OrderPhase.waiting:
        activePanel = TrackOrderInfoPanel(
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
      case OrderPhase.riderHeadingToStore:
        activePanel = TrackOrderInfoPanel(
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
      case OrderPhase.riderComingToPickup:
      case OrderPhase.riderComingToDeliver:
        activePanel = _MapPanelWrapper(
          key: ValueKey('map_$_status'),
          order: order,
          isDark: isDark,
          phase: _phase,
          activeRiderId: _activeRiderId,
        );
        break;
      case OrderPhase.atStore:
      case OrderPhase.cleaning:
      case OrderPhase.ready:
        activePanel = TrackOrderCleaningPanel(
          key: ValueKey('cleaning_$_status'),
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
              _MultiOrderServicesList(groupOrders: groupOrders, isDark: isDark),
              const SizedBox(height: 18),
              _PhaseBannerResolver(phase: _phase, isDark: isDark),
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

class _MapPanelWrapper extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final OrderPhase phase;
  final String? activeRiderId;

  const _MapPanelWrapper({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
    this.activeRiderId,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<RiderTrackingBloc>(),
    child: Column(
      children: [
        TrackOrderMapView(
          order: order,
          isDark: isDark,
          phase: phase,
          activeRiderId: activeRiderId,
        ),
        const SizedBox(height: 18),
        TrackOrderDetailsCard(order: order, isDark: isDark, phase: phase),
      ],
    ),
  );
}

class _PhaseBannerResolver extends StatelessWidget {
  final OrderPhase phase;
  final bool isDark;

  const _PhaseBannerResolver({required this.phase, required this.isDark});

  _PhaseCfg get _cfg {
    switch (phase) {
      case OrderPhase.waiting:
        return const _PhaseCfg(
          Iconsax.clock,
          AppColors.warning,
          'Preparing Order',
          'We are processing your order details.',
        );
      case OrderPhase.riderComingToPickup:
        return const _PhaseCfg(
          Iconsax.car,
          AppColors.primary,
          'Rider Dispatched',
          'A rider is on their way to pick up your laundry.',
        );
      case OrderPhase.riderHeadingToStore:
        return const _PhaseCfg(
          Iconsax.truck_fast,
          AppColors.warning,
          'Heading to Store',
          'Rider is taking your items to the facility.',
        );
      case OrderPhase.atStore:
        return const _PhaseCfg(
          Iconsax.shop,
          Color(0xFF8B5CF6),
          'Items at the Store',
          'Your laundry has safely arrived.',
        );
      case OrderPhase.cleaning:
        return const _PhaseCfg(
          Iconsax.refresh,
          AppColors.info,
          'Cleaning in Progress',
          'Our team is washing & drying your laundry.',
        );
      case OrderPhase.ready:
        return const _PhaseCfg(
          Iconsax.box_1,
          AppColors.success,
          'Packed & Ready',
          'Your laundry is fresh and ready to be dispatched.',
        );
      case OrderPhase.riderComingToDeliver:
        return const _PhaseCfg(
          Iconsax.truck_fast,
          Color(0xFF8B5CF6),
          'On the Way',
          'Your fresh laundry is headed to your address.',
        );
      default:
        return const _PhaseCfg(
          Iconsax.info_circle,
          AppColors.primary,
          'Processing',
          'Your order is being handled.',
        );
    }
  }

  @override
  Widget build(BuildContext context) => AppPhaseBanner(
    icon: _cfg.icon,
    color: _cfg.color,
    title: _cfg.title,
    subtitle: _cfg.subtitle,
    isDark: isDark,
  );
}

class _PhaseCfg {
  final IconData icon;
  final Color color;
  final String title, subtitle;

  const _PhaseCfg(this.icon, this.color, this.title, this.subtitle);
}

class _DeliveredView extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  const _DeliveredView({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => AppStatusResultView(
    isDark: isDark,
    iconData: Icons.check_rounded,
    gradient: AppColors.gradient,
    glowColor: AppColors.primary,
    title: 'Order Delivered!',
    subtitle: 'Your laundry has been delivered.\nThank you for using EzeeWash!',
    borderColor: AppColors.primary,
    summaryRows: [
      AppSummaryRow(
        icon: Icons.tag_rounded,
        label: 'Order',
        value: '#${order.orderNumber}',
        isDark: isDark,
      ),
      AppSummaryRow(
        icon: Iconsax.drop,
        label: 'Service',
        value: order.serviceName,
        isDark: isDark,
      ),
      AppSummaryRow(
        icon: Iconsax.shop,
        label: 'Store',
        value: order.storeName,
        isDark: isDark,
      ),

      // ── NEW: Injects the Discount Row cleanly into the Delivered receipt ──
      if (order.discountAmount > 0)
        AppSummaryRow(
          icon: Iconsax.ticket_discount,
          label: 'Discount Applied',
          value: '- ৳${order.discountAmount.toStringAsFixed(0)}',
          isDark: isDark,
          valueColor: const Color(0xFF2ECC71), // Vibrant Green Text
        ),

      AppSummaryRow(
        icon: Iconsax.money,
        label: 'Total Paid',
        value: '৳${order.totalPrice.toStringAsFixed(0)}',
        isDark: isDark,
        highlight: true,
      ),
    ],
    buttonLabel: 'Done',
    buttonColor: AppColors.primary,
    onButton: () => context.pop(),
  );
}

class _CancelledView extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;

  const _CancelledView({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) => AppStatusResultView(
    isDark: isDark,
    iconData: Icons.close_rounded,
    gradient: const LinearGradient(
      colors: [AppColors.error, Color(0xFFEF4444)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glowColor: AppColors.error,
    title: 'Order Cancelled',
    subtitle:
        'This order has been cancelled and no charges were applied.\nWe hope to serve you again soon.',
    borderColor: AppColors.error,
    summaryRows: [
      AppSummaryRow(
        icon: Icons.tag_rounded,
        label: 'Order',
        value: '#${order.orderNumber}',
        isDark: isDark,
      ),
      AppSummaryRow(
        icon: Iconsax.drop,
        label: 'Service',
        value: order.serviceName,
        isDark: isDark,
      ),
      AppSummaryRow(
        icon: Iconsax.shop,
        label: 'Store',
        value: order.storeName,
        isDark: isDark,
      ),
    ],
    buttonLabel: 'Go Back',
    buttonColor: AppColors.error,
    buttonOutlined: true,
    onButton: () => context.pop(),
    animDuration: const Duration(milliseconds: 600),
  );
}

class _MultiOrderServicesList extends StatelessWidget {
  final List<OrderEntity> groupOrders;
  final bool isDark;

  const _MultiOrderServicesList({
    required this.groupOrders,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Included Services',
            style: AppTextStyles.rowTitle(isDark).copyWith(
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...groupOrders.map((o) {
            final progress = OrderStatus.getProgress(o.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppNetworkImage(
                        url: o.serviceImageUrl?.toString(),
                        width: 44,
                        height: 44,
                        radius: 12,
                        isDark: isDark,
                        fallbackIcon: Icons.local_laundry_service,
                        fallbackIconSize: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.serviceName,
                              style: AppTextStyles.cardTitle(isDark).copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${o.itemCount} item${o.itemCount > 1 ? 's' : ''} • #${o.orderNumber}',
                              style: AppTextStyles.subtitle(isDark).copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppStatusBadge(status: o.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.caption(isDark),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTextStyles.captionMedium(isDark).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: v,
                        backgroundColor: isDark 
                            ? Colors.white12 
                            : AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
