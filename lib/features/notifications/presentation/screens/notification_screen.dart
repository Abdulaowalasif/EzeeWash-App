// lib/features/notifications/presentation/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
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
                  return _NotificationsShimmer(isDark: isDark);
                }
                if (state is NotificationsError) {
                  return _NotificationsError(
                      message: state.message, isDark: isDark);
                }
                if (state is NotificationsLoaded) {
                  if (state.notifications.isEmpty) {
                    return _NotificationsEmpty(isDark: isDark);
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

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

class _NotificationsShimmer extends StatelessWidget {
  final bool isDark;
  const _NotificationsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppShimmerColors.base(isDark),
      highlightColor: AppShimmerColors.highlight(isDark),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context), 16,
          Responsive.horizontalPadding(context), 30,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) =>
        const AppShimmerBox(height: 90, radius: 18),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _NotificationsError extends StatelessWidget {
  final String message;
  final bool isDark;
  const _NotificationsError(
      {required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2,
                size: 64,
                color: isDark
                    ? AppColors.darkSubtext
                    : AppColors.lightSubtext),
            const SizedBox(height: 16),
            Text('Could not load notifications',
                style: AppTextStyles.cardTitle(isDark)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(isDark)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try Again',
                  style: AppTextStyles.button),
              onPressed: () => context
                  .read<NotificationsBloc>()
                  .add(const NotificationsLoadRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _NotificationsEmpty extends StatelessWidget {
  final bool isDark;
  const _NotificationsEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Iconsax.notification_bing,
      message: 'No notifications yet',
      subtitle: "You'll see order updates and promotions here.",
      isDark: isDark,
    );
  }
}

// ─── Loaded list ──────────────────────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  final List<NotificationEntity> notifications;
  final bool isDark;

  const _NotificationsList({
    required this.notifications,
    required this.isDark,
  });

  void _handleTap(BuildContext context, NotificationEntity notif) {
    if (!notif.isRead) {
      context
          .read<NotificationsBloc>()
          .add(NotificationMarkReadRequested(notif.id));
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
        Responsive.horizontalPadding(context), 16,
        Responsive.horizontalPadding(context), 30,
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
              : () => context
              .read<NotificationsBloc>()
              .add(NotificationMarkReadRequested(notif.id)),
        );
      },
    );
  }
}