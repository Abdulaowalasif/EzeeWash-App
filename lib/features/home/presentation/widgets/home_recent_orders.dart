// lib/features/home/presentation/widgets/home_recent_orders.dart

import 'package:ezzewash/core/widgets/app_error_state.dart';
import 'package:ezzewash/core/widgets/app_shimmer.dart';
import 'package:ezzewash/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../routes/routes_name.dart';
import '../../../orders/presentation/bloc/order_event.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_state.dart';
import '../../../orders/domain/entities/order_entity.dart';

class HomeRecentOrders extends StatelessWidget {
  final bool isDark;

  const HomeRecentOrders({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersInitial || state is OrdersLoading) {
          return AppShimmer.recentOrderList(isDark: isDark);
        }
        if (state is OrdersLoaded) {
          final activeOrders = state.orders.where((o) => o.isActive).toList();
          
          final Map<String, List<OrderEntity>> groupedMap = {};
          final List<OrderEntity> displayed = [];

          for (final order in activeOrders) {
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
              itemCount: group.fold<int>(0, (sum, o) => sum + o.itemCount),
              totalPrice: group.fold<double>(0.0, (sum, o) => sum + o.totalPrice),
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
          
          displayed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final recent = displayed.take(2).toList();

          if (recent.isEmpty) {
            return Center(
              child: Text(
                'No orders yet. Book your first service!',
                style: AppTextStyles.caption(isDark),
              ),
            );
          }
          return Column(
            children: recent
                .map<Widget>(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RecentOrderCard(
                      orderId: order.id,
                      orderNumber: '#${order.orderNumber}',
                      serviceName: order.serviceName,
                      status: order.status,
                      progress: order.progress,
                      imageUrl: order.serviceImageUrl?.toString(),
                      isDark: isDark,
                    ),
                  ),
                )
                .toList(),
          );
        }
        if (state is OrdersError) {
          return AppErrorState(
            message: "Could not load recent orders",
            isDark: isDark,
            onRetry: () =>
                context.read<OrdersBloc>().add(OrdersLoadRequested()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class RecentOrderCard extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final String serviceName;
  final String status;
  final double progress;
  final String? imageUrl;
  final bool isDark;

  const RecentOrderCard({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.serviceName,
    required this.status,
    required this.progress,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RoutesName.trackOrdersNavigate, extra: orderId),
      child: AppCard(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        borderRadius: 18,
        child: Column(
          children: [
            _OrderCardHeader(
              orderNumber: orderNumber,
              serviceName: serviceName,
              status: status,
              imageUrl: imageUrl,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            AppOrderProgressBar(
              progress: progress,
              status: status,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCardHeader extends StatelessWidget {
  final String orderNumber;
  final String serviceName;
  final String status;
  final String? imageUrl;
  final bool isDark;

  const _OrderCardHeader({
    required this.orderNumber,
    required this.serviceName,
    required this.status,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppNetworkImage(
          url: imageUrl,
          width: 54,
          height: 54,
          radius: 14,
          isDark: isDark,
          fallbackIcon: Icons.local_laundry_service,
          fallbackIconSize: 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orderNumber, style: AppTextStyles.rowTitle(isDark)),
              Text(serviceName, style: AppTextStyles.subtitle(isDark)),
            ],
          ),
        ),
        AppStatusBadge(status: status),
      ],
    );
  }
}
