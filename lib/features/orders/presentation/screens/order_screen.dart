// lib/features/orders/presentation/screens/order_screen.dart
import 'dart:async';

import 'package:ezzewash/core/widgets/app_error_state.dart';
import 'package:ezzewash/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_gradient_fab.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../models/order_filter.dart';
import '../widgets/order screen/order_screen_widgets.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  OrderFilter _filter = const OrderFilter();

  Future<void> _showFilterSheet(
    BuildContext ctx,
    List<OrderEntity> allOrders,
  ) async {
    final result = await showModalBottomSheet<OrderFilter>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderFilterSheet(current: _filter, allOrders: allOrders),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: GradientAppBar(
        title: 'My Orders',
        backEnabled: false,
        trailing: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (ctx, state) {
            if (state is! OrdersLoaded) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => _showFilterSheet(ctx, state.orders),
              child: _FilterIconButton(activeCount: _filter.activeCount),
            );
          },
        ),
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (_, s) => s is OrderCancelled || s is OrdersError,
        buildWhen: (_, current) =>
            current is OrdersInitial ||
            current is OrdersLoading ||
            current is OrdersLoaded ||
            current is OrdersError,
        listener: (context, state) {
          if (state is OrderCancelled) {
            AppSnackBar.show(context, 'Order cancelled.');
          } else if (state is OrdersError) {
            AppSnackBar.show(context, state.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is OrdersInitial || state is OrdersLoading) {
            return AppShimmer.orderList(isDark: isDark);
          }
          if (state is OrdersError) {
            return AppErrorState(
              message: "Couldn't load orders",
              isDark: isDark,
              onRetry: () =>
                  context.read<OrdersBloc>().add(const OrdersLoadRequested()),
            );
          }
          if (state is OrdersLoaded) {
            return _OrdersBody(
              state: state,
              isDark: isDark,
              filter: _filter,
              onClearFilter: () =>
                  setState(() => _filter = const OrderFilter()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: AppGradientFab(
        icon: Iconsax.add,
        onPressed: () => context.push(RoutesName.placeOrdersNavigate),
      ),
    );
  }
}

// ─── Filter icon with badge ───────────────────────────────────────────────────

class _FilterIconButton extends StatelessWidget {
  final int activeCount;

  const _FilterIconButton({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.filter_list_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (activeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$activeCount',
                  style: AppTextStyles.caption(true).copyWith(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Orders body ──────────────────────────────────────────────────────────────

class _OrdersBody extends StatefulWidget {
  final OrdersLoaded state;
  final bool isDark;
  final OrderFilter filter;
  final VoidCallback onClearFilter;

  const _OrdersBody({
    required this.state,
    required this.isDark,
    required this.filter,
    required this.onClearFilter,
  });

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  late PageController _pageController;
  late bool _showActive;

  @override
  void initState() {
    super.initState();
    _showActive = widget.state.showActive;
    _pageController = PageController(initialPage: _showActive ? 0 : 1);
  }

  @override
  void didUpdateWidget(covariant _OrdersBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.showActive != widget.state.showActive &&
        _showActive != widget.state.showActive) {
      _showActive = widget.state.showActive;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _showActive ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildList(List<OrderEntity> rawDisplayed, bool isActiveTab) {
    // ── GROUP ORDERS BY GROUP ID ──
    final Map<String, List<OrderEntity>> groupedMap = {};
    final List<OrderEntity> displayed = [];

    for (final order in rawDisplayed) {
      if (order.groupId != null && order.groupId!.isNotEmpty) {
        if (!groupedMap.containsKey(order.groupId)) {
          groupedMap[order.groupId!] = [];
        }
        groupedMap[order.groupId!]!.add(order);
      } else {
        displayed.add(order);
      }
    }

    for (final group in groupedMap.values) {
      if (group.length == 1) {
        displayed.add(group.first);
        continue;
      }

      final primary = group.first;
      double totalP = 0.0;
      int totalItems = 0;
      for (final o in group) {
        totalP += o.totalPrice;
        totalItems += o.itemCount;
      }
      
      final merged = OrderEntity(
        id: primary.id,
        orderNumber: primary.orderNumber,
        userId: primary.userId,
        serviceId: primary.serviceId,
        serviceName: '${group.length} Services',
        serviceImageUrl: primary.serviceImageUrl,
        storeId: primary.storeId,
        storeName: primary.storeName,
        status: primary.status,
        itemCount: totalItems,
        totalPrice: totalP,
        pickupAddress: primary.pickupAddress,
        deliveryAddress: primary.deliveryAddress,
        pickupDate: primary.pickupDate,
        pickupTime: primary.pickupTime,
        deliveryDate: primary.deliveryDate,
        deliveryTime: primary.deliveryTime,
        specialInstructions: primary.specialInstructions,
        progress: primary.progress,
        timeline: primary.timeline,
        createdAt: primary.createdAt,
        paymentMethod: primary.paymentMethod,
        paymentStatus: primary.paymentStatus,
        stripePaymentIntentId: primary.stripePaymentIntentId,
        couponCode: primary.couponCode,
        discountAmount: primary.discountAmount,
        groupId: primary.groupId,
        riderLat: primary.riderLat,
        riderLng: primary.riderLng,
        riderId: primary.riderId,
        pickupRiderId: primary.pickupRiderId,
        deliveryRiderId: primary.deliveryRiderId,
        riderName: primary.riderName,
        riderPhone: primary.riderPhone,
        riderAvatarUrl: primary.riderAvatarUrl,
        riderVehicleType: primary.riderVehicleType,
        riderVehiclePlate: primary.riderVehiclePlate,
        riderRating: primary.riderRating,
        riderIsOnline: primary.riderIsOnline,
      );
      displayed.add(merged);
    }
    
    // Maintain descending sort by date
    displayed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (displayed.isEmpty) {
      return AppEmptyState(
        icon: widget.filter.isActive
            ? Iconsax.search_normal
            : (isActiveTab ? Iconsax.truck_fast : Iconsax.box),
        message: widget.filter.isActive
            ? 'No orders match your filters'
            : (isActiveTab ? 'No active orders' : 'No completed orders'),
        subtitle: widget.filter.isActive
            ? 'Try adjusting or clearing your filters'
            : (isActiveTab
                  ? 'Tap + to book your first laundry service'
                  : 'Completed orders will appear here'),
        isDark: widget.isDark,
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: displayed.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final order = displayed[i];
        final tab = isActiveTab ? 'a' : 'h';
        
        // Find if this is a merged multi-order by looking for it in groupedMap
        List<OrderEntity>? group;
        if (order.groupId != null && groupedMap.containsKey(order.groupId)) {
          final g = groupedMap[order.groupId!];
          if (g != null && g.length > 1) {
            group = g;
          }
        }

        return OrderCard(
          key: ValueKey('${tab}_${order.id}'),
          order: order,
          groupOrders: group,
          isHistory: !isActiveTab,
          isDark: widget.isDark,
          onPress: () =>
              context.push(RoutesName.trackOrdersNavigate, extra: order.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.state.orders.where((o) => o.isActive).toList();
    final historyOrders = widget.state.orders
        .where((o) => !o.isActive)
        .toList();
    final activeDisplayed = widget.filter.apply(activeOrders);
    final historyDisplayed = widget.filter.apply(historyOrders);
    final currentDisplayed = _showActive ? activeDisplayed : historyDisplayed;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        16,
        Responsive.horizontalPadding(context),
        0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: Column(
            children: [
              OrdersToggle(
                showActive: _showActive,
                isDark: widget.isDark,
                pageController: _pageController,
                onChanged: (active) {
                  setState(() => _showActive = active);
                  _pageController.animateToPage(
                    active ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  context.read<OrdersBloc>().add(OrdersFilterToggled(active));
                },
              ),
              if (widget.filter.isActive) ...[
                const SizedBox(height: 10),
                OrderActiveFilterBar(
                  filter: widget.filter,
                  isDark: widget.isDark,
                  onClear: widget.onClearFilter,
                  allOrders: widget.state.orders,
                ),
              ],
              const SizedBox(height: 12),
              if (widget.filter.isActive)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${currentDisplayed.length} result${currentDisplayed.length == 1 ? '' : 's'}',
                    style: AppTextStyles.caption(
                      widget.isDark,
                    ).copyWith(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (idx) {
                    final isActive = idx == 0;
                    if (isActive != _showActive) {
                      setState(() => _showActive = isActive);
                    }
                    if (isActive != widget.state.showActive) {
                      context.read<OrdersBloc>().add(
                        OrdersFilterToggled(isActive),
                      );
                    }
                  },
                  children: [
                    _buildList(activeDisplayed, true),
                    _buildList(historyDisplayed, false),
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
