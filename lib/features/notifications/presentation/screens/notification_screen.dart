// lib/features/notifications/presentation/screens/notification_screen.dart

import 'package:ezzewash/core/widgets/app_error_state.dart';
import 'package:ezzewash/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_widgets.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          const NotificationsAppBar(),
          Expanded(
            child: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is NotificationsInitial ||
                    state is NotificationsLoading) {
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Responsive.horizontalPadding(context),
                      16,
                      Responsive.horizontalPadding(context),
                      30,
                    ),
                    child: AppShimmer.notificationList(
                      isDark: isDark,
                      itemCount: 6,
                    ),
                  );
                }

                if (state is NotificationsError) {
                  return AppErrorState(
                    message: "Could not load notifications",
                    isDark: isDark,
                    onRetry: () => context.read<NotificationsBloc>().add(
                      const NotificationsLoadRequested(),
                    ),
                  );
                }

                if (state is NotificationsLoaded) {
                  if (state.notifications.isEmpty) {
                    return AppEmptyState(
                      icon: Iconsax.notification_bing,
                      message: 'No notifications yet',
                      subtitle: "You'll see order updates and promotions here.",
                      isDark: isDark,
                    );
                  }

                  return _NotificationsList(
                    notifications: state.notifications,
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loaded list ──────────────────────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  final List<NotificationEntity> notifications;
  final bool isDark;

  const _NotificationsList(
      {required this.notifications, required this.isDark});

  void _handleTap(BuildContext context, NotificationEntity notif) {
    if (!notif.isRead) {
      context.read<NotificationsBloc>().add(
        NotificationMarkReadRequested(notif.id),
      );
    }
    if (notif.type == 'order_update' && notif.orderId != null) {
      context.push(RoutesName.trackOrdersNavigate, extra: notif.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        16,
        Responsive.horizontalPadding(context),
        30,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final notif = notifications[i];
        return NotificationCard(
          notification: notif,
          isDark: isDark,
          onTap: () => _handleTap(context, notif),
          onMarkRead: notif.isRead
              ? null
              : () => context.read<NotificationsBloc>().add(
            NotificationMarkReadRequested(notif.id),
          ),
        );
      },
    );
  }
}