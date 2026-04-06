// lib/features/notifications/presentation/widgets/notifications_app_bar.dart
//
// GradientAppBar extended with a "Mark All Read" action button
// that only appears when there are unread notifications.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../bloc/notifications_bloc.dart';

class NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const NotificationsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      title: 'Notifications',
      backEnabled: false,
      trailing: BlocBuilder<NotificationsBloc, NotificationsState>(
        buildWhen: (prev, curr) {
          // Only rebuild when the hasUnread flag changes.
          final prevUnread =
              prev is NotificationsLoaded && prev.hasUnread;
          final currUnread =
              curr is NotificationsLoaded && curr.hasUnread;
          return prevUnread != currUnread;
        },
        builder: (context, state) {
          if (state is! NotificationsLoaded || !state.hasUnread) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: () => context
                .read<NotificationsBloc>()
                .add(const NotificationsMarkAllReadRequested()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Mark All Read',
                style: AppTextStyles.buttonSmall,
              ),
            ),
          );
        },
      ),
    );
  }
}
