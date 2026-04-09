// lib/features/home/presentation/widgets/home_recent_orders.dart

import 'package:ezzewash/core/widgets/app_error_state.dart';
import 'package:ezzewash/core/widgets/app_shimmer.dart';
import 'package:ezzewash/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_order_progress_bar.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../routes/routes_name.dart';
import '../../../orders/presentation/bloc/order_event.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_state.dart';

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
          final recent = state.orders.take(2).toList();
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
                .map(
                  (order) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecentOrderCard(
                  orderId: order.id,
                  orderNumber: '#${order.orderNumber}',
                  serviceName: order.serviceName,
                  status: order.status,
                  progress: order.progress,
                  imageUrl: order.serviceImageUrl.toString(),
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