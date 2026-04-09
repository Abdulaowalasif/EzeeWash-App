// lib/features/notifications/presentation/screens/notification_screen.dart

import 'package:ezzewash/core/widgets/app_error_state.dart';
import 'package:ezzewash/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notifications_bloc.dart';
import '../widgets/notification_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ─── STATE MANAGEMENT ───
  late final PageController _pageController;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onToggleChanged(bool val) {
    setState(() => _showActive = val);
    _pageController.animateToPage(
      val ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          const NotificationsAppBar(),

          // ─── THE TOGGLE ───
          Padding(
            padding: EdgeInsetsGeometry.fromLTRB(  Responsive.horizontalPadding(context),
              16,
              Responsive.horizontalPadding(context),
              5,),
            child: NotificationToggle(
              showActive: _showActive,
              isDark: isDark,
              onChanged: _onToggleChanged,
              pageController: _pageController,
            ),
          ),

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
                  // ─── FILTERING LOGIC ───
                  final orderUpdates = state.notifications
                      .where((n) => n.type != 'promo')
                      .toList();
                  final promos = state.notifications
                      .where((n) => n.type == 'promo')
                      .toList();

                  return PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _showActive = index == 0),
                    children: [
                      // TAB 1: Order Updates
                      _buildListOrEmpty(
                        context,
                        orderUpdates,
                        isDark,
                        'No order updates yet',
                      ),
                      // TAB 2: Promos
                      _buildListOrEmpty(
                        context,
                        promos,
                        isDark,
                        'No promotions available',
                      ),
                    ],
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

  Widget _buildListOrEmpty(BuildContext context,
      List<NotificationEntity> items, bool isDark, String emptyMsg) {
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Iconsax.notification_bing,
        message: emptyMsg,
        subtitle: "Check back later for more updates.",
        isDark: isDark,
      );
    }
    return _NotificationsList(notifications: items, isDark: isDark);
  }
}

// ─── LOADED LIST VIEW ───

class _NotificationsList extends StatelessWidget {
  final List<NotificationEntity> notifications;
  final bool isDark;

  const _NotificationsList({required this.notifications, required this.isDark});

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

// ─── THE TOGGLE WIDGET ───

class NotificationToggle extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final PageController pageController;

  const NotificationToggle({
    super.key,
    required this.showActive,
    required this.isDark,
    required this.onChanged,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          // ─── Sliding Selection Background ───
          AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double page = showActive ? 0.0 : 1.0;

              if (pageController.hasClients &&
                  pageController.position.haveDimensions) {
                page = pageController.page ?? page;
              }

              page = page.clamp(0.0, 1.0);
              final alignmentX = (page * 2) - 1.0;

              return Align(
                alignment: Alignment(alignmentX, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ─── Tab Labels ───
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.caption(true).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: showActive
                            ? Colors.white
                            : (isDark
                            ? AppColors.darkSubtext
                            : Colors.grey.shade600),
                      ),
                      child: const Text('Order Updates'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(false),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.caption(true).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: !showActive
                            ? Colors.white
                            : (isDark
                            ? AppColors.darkSubtext
                            : Colors.grey.shade600),
                      ),
                      child: const Text('Promo'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}