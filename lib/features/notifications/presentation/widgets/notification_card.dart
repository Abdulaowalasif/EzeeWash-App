// lib/features/notifications/presentation/widgets/notification_card.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback onTap;

  /// Non-null only when unread — powers the swipe-to-read action.
  final VoidCallback? onMarkRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isDark,
    required this.onTap,
    this.onMarkRead,
  });

  // ─── Type helpers ──────────────────────────────────────────────────────────

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

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    Widget card = _CardBody(
      notification: notification,
      isDark: isDark,
      isUnread: isUnread,
      icon: _icon,
      iconColor: _iconColor,
      isNavigable: _isNavigable,
      onTap: onTap,
    );

    if (isUnread && onMarkRead != null) {
      card = Dismissible(
        key: ValueKey('notif_${notification.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onMarkRead?.call();
          return false; // bloc handles the UI update optimistically
        },
        background: _SwipeBackground(isDark: isDark),
        child: card,
      );
    }

    return card;
  }
}

// ─── Card body ────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final bool isUnread;
  final IconData icon;
  final Color iconColor;
  final bool isNavigable;
  final VoidCallback onTap;

  const _CardBody({
    required this.notification,
    required this.isDark,
    required this.isUnread,
    required this.icon,
    required this.iconColor,
    required this.isNavigable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(
                      notification: notification,
                      isDark: isDark,
                      isUnread: isUnread),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.subtitle(isDark)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(
                      notification: notification,
                      isDark: isDark,
                      isUnread: isUnread,
                      isNavigable: isNavigable),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final bool isUnread;

  const _TitleRow({
    required this.notification,
    required this.isDark,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            notification.title,
            style: AppTextStyles.rowTitle(isDark).copyWith(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isUnread)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final bool isUnread;
  final bool isNavigable;

  const _MetaRow({
    required this.notification,
    required this.isDark,
    required this.isUnread,
    required this.isNavigable,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        _formatDate(notification.createdAt),
        style: AppTextStyles.caption(isDark).copyWith(
          color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
              .withOpacity(0.7),
        ),
      ),
      // "Track order" pill for new navigable notifications
      if (isNavigable && isUnread) ...[
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
              Text(
                'Track order',
                style: AppTextStyles.tiny(isDark).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      // Chevron for already-read navigable notifications
      if (isNavigable && !isUnread)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 10,
            color: (isDark ? AppColors.darkSubtext : AppColors.lightSubtext)
                .withOpacity(0.5),
          ),
        ),
    ]);
  }
}

// ─── Swipe background ─────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final bool isDark;
  const _SwipeBackground({required this.isDark});

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
          Text(
            'Mark read',
            style: AppTextStyles.captionMedium(isDark)
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
