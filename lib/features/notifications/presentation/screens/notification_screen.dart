// lib/features/notifications/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/revponsive.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              10,
              Responsive.horizontalPadding(context),
              10,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                BlocBuilder<NotificationsBloc, NotificationsState>(
                  builder: (context, state) {
                    if (state is NotificationsLoaded &&
                        state.unreadCount > 0) {
                      return GestureDetector(
                        onTap: () => context
                            .read<NotificationsBloc>()
                            .add(const NotificationMarkAllRead()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mark All Read',
                            style: GoogleFonts.alexandria(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.notification_bing,
                      size: 72,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.alexandria(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 10,
              ),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final notif = state.notifications[i];
                return _NotificationCard(
                  notification: notif,
                  isDark: isDark,
                  onTap: () => context
                      .read<NotificationsBloc>()
                      .add(NotificationMarkRead(notif.id)),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'order_update':
        return Iconsax.truck_fast;
      case 'promo':
        return Iconsax.discount_circle;
      default:
        return Iconsax.notification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.05))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withOpacity(0.3)
                : (isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.alexandria(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightText,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
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
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, y').format(dt);
  }
}
