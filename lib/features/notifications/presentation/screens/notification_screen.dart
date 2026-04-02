// lib/features/notifications/presentation/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      // Replaced standard AppBar with a Column layout to use custom header
      body: Column(
        children: [
          // 🚀 Fixed Custom Header matching Home, Service, and Order screens
          _NotificationsAppBar(isDark: isDark),

          Expanded(
            child: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                // ── Initial / Loading ────────────────────────────────────────────
                if (state is NotificationsInitial || state is NotificationsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                // ── Error ────────────────────────────────────────────────────────
                if (state is NotificationsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 64,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load notifications',
                            style: GoogleFonts.alexandria(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alexandria(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              'Try Again',
                              style: GoogleFonts.alexandria(
                                  fontWeight: FontWeight.w600),
                            ),
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

                // ── Loaded ───────────────────────────────────────────────────────
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
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see order updates and promotions here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.alexandria(
                              fontSize: 13,
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
                    physics: const BouncingScrollPhysics(),
                    // Manually control padding to prevent automatic SafeArea gap
                    padding: EdgeInsets.fromLTRB(
                      Responsive.horizontalPadding(context),
                      16,
                      Responsive.horizontalPadding(context),
                      30,
                    ),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final notif = state.notifications[i];
                      return _NotificationCard(
                        notification: notif,
                        isDark: isDark,
                        onTap: notif.isRead
                            ? null // already read — no action needed
                            : () => context
                            .read<NotificationsBloc>()
                            .add(NotificationMarkReadRequested(notif.id)),
                      );
                    },
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

// ─── Custom App Bar ───────────────────────────────────────────────────────────

class _NotificationsAppBar extends StatelessWidget {
  final bool isDark;

  const _NotificationsAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              // Mark All Read button — only shown when there are unread
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoaded && state.hasUnread) {
                    return GestureDetector(
                      onTap: () => context
                          .read<NotificationsBloc>()
                          .add(const NotificationsMarkAllReadRequested()),
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
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'order_update':
        return Iconsax.truck_fast;
      case 'promo':
        return Iconsax.discount_circle;
      case 'welcome':
        return Iconsax.star;
      default:
        return Iconsax.notification;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'order_update': return AppColors.primary;
      case 'promo':        return const Color(0xFF8B5CF6);
      case 'welcome':      return AppColors.success;
      default:             return AppColors.primary;
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
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(width: 8),
                      // Unread dot
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
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
                          ? AppColors.darkSubtext.withOpacity(0.7)
                          : AppColors.lightSubtext.withOpacity(0.7),
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
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }
}