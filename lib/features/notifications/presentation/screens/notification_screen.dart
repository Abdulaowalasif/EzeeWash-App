// lib/features/notifications/presentation/screens/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
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
      body: Column(
        children: [
          _NotificationsAppBar(isDark: isDark),
          Expanded(
            child: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is NotificationsInitial ||
                    state is NotificationsLoading) {
                  return _NotificationsShimmer(isDark: isDark);
                }

                if (state is NotificationsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.warning_2, size: 64,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          const SizedBox(height: 16),
                          Text('Could not load notifications',
                              style: GoogleFonts.alexandria(
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.lightText)),
                          const SizedBox(height: 8),
                          Text(state.message, textAlign: TextAlign.center,
                              style: GoogleFonts.alexandria(fontSize: 13,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text('Try Again',
                                style: GoogleFonts.alexandria(fontWeight: FontWeight.w600)),
                            onPressed: () => context.read<NotificationsBloc>()
                                .add(const NotificationsLoadRequested()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is NotificationsLoaded) {
                  if (state.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.notification_bing, size: 72,
                              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                          const SizedBox(height: 16),
                          Text('No notifications yet',
                              style: GoogleFonts.alexandria(fontSize: 16,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                          const SizedBox(height: 8),
                          Text('You\'ll see order updates and promotions here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.alexandria(fontSize: 13,
                                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      Responsive.horizontalPadding(context), 16,
                      Responsive.horizontalPadding(context), 30,
                    ),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final notif = state.notifications[i];
                      return _NotificationCard(
                        notification: notif,
                        isDark: isDark,
                        onTap: () => _handleTap(context, notif),
                        onMarkRead: notif.isRead
                            ? null
                            : () => context.read<NotificationsBloc>()
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

  /// Tap handler:
  /// 1. Always marks the notification as read if it is unread.
  /// 2. Navigates to TrackOrderScreen with the orderId when type == 'order_update'
  ///    and an orderId is present. Other notification types just mark as read.
  void _handleTap(BuildContext context, NotificationEntity notif) {
    if (!notif.isRead) {
      context.read<NotificationsBloc>()
          .add(NotificationMarkReadRequested(notif.id));
    }
    if (notif.type == 'order_update' && notif.orderId != null) {
      context.push(RoutesName.trackOrdersNavigate, extra: notif.orderId);
    }
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────

class _NotificationsShimmer extends StatelessWidget {
  final bool isDark;
  const _NotificationsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context), 16,
          Responsive.horizontalPadding(context), 30,
        ),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(
          height: 90,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
        ),
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
          BoxShadow(color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications',
                  style: GoogleFonts.alexandria(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoaded && state.hasUnread) {
                    return GestureDetector(
                      onTap: () => context.read<NotificationsBloc>()
                          .add(const NotificationsMarkAllReadRequested()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Mark All Read',
                            style: GoogleFonts.alexandria(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;

  /// Always present — marks read and navigates when applicable.
  final VoidCallback onTap;

  /// Non-null only when the notification is unread.
  /// Used as the swipe-to-mark-read action (alternative to tapping).
  final VoidCallback? onMarkRead;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    this.onMarkRead,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'order_update': return Iconsax.truck_fast;
      case 'promo':        return Iconsax.discount_circle;
      case 'welcome':      return Iconsax.star;
      default:             return Iconsax.notification;
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

  bool get _isNavigable =>
      notification.type == 'order_update' && notification.orderId != null;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    Widget card = _buildCard(isUnread);

    // Wrap with Dismissible for unread cards: swipe left → mark as read
    if (isUnread && onMarkRead != null) {
      card = Dismissible(
        key: ValueKey('notif_${notification.id}'),
        direction: DismissDirection.endToStart,
        // Return false so Flutter doesn't remove the widget —
        // the bloc optimistic update rebuilds the list with isRead=true instead.
        confirmDismiss: (_) async {
          onMarkRead?.call();
          return false;
        },
        background: _SwipeReadBackground(isDark: isDark),
        child: card,
      );
    }

    return card;
  }

  Widget _buildCard(bool isUnread) {
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
              : [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(notification.title,
                            style: GoogleFonts.alexandria(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppColors.lightText,
                            )),
                      ),
                      const SizedBox(width: 8),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body,
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        height: 1.4,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(_formatDate(notification.createdAt),
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkSubtext.withOpacity(0.7)
                                : AppColors.lightSubtext.withOpacity(0.7),
                          )),

                      // "Track order" pill — navigable & unread
                      if (_isNavigable && isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.location, size: 10, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text('Track order',
                                  style: GoogleFonts.alexandria(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  )),
                            ],
                          ),
                        ),
                      ],

                      // Chevron — navigable & already read
                      if (_isNavigable && !isUnread)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: isDark
                                  ? AppColors.darkSubtext.withOpacity(0.5)
                                  : AppColors.lightSubtext.withOpacity(0.5)),
                        ),
                    ],
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

// ─── Swipe-to-read background revealed behind the card ───────────────────────

class _SwipeReadBackground extends StatelessWidget {
  final bool isDark;
  const _SwipeReadBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.tick_circle, color: AppColors.primary, size: 22),
          const SizedBox(height: 4),
          Text('Mark read',
              style: GoogleFonts.alexandria(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ],
      ),
    );
  }
}