// lib/features/home/screens/home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ezzewash/features/screens/track_order_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_state.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../services/presentation/bloc/service_bloc.dart';
import '../../../services/presentation/bloc/service_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _localQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _HomeAppBar(isDark: isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 15,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.maxContentWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _SearchBox(
                          isDark: isDark,
                          onChanged: (q) => setState(() => _localQuery = q),
                        ),
                        const SizedBox(height: 25),
                        _SectionHeader(
                          title: 'Our Services',
                          onViewAll: () => context.go(RoutesName.services),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 15),
                        _ServicesGrid(
                          isDark: isDark,
                          crossAxisCount: Responsive.gridCount(context),
                          localQuery: _localQuery,
                        ),
                        const SizedBox(height: 30),
                        _QuickActions(isDark: isDark),
                        const SizedBox(height: 30),
                        _SectionHeader(
                          title: 'Recent Orders',
                          onViewAll: () => context.go(RoutesName.orders),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 15),
                        _RecentOrdersList(isDark: isDark),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== App Bar =====
class _HomeAppBar extends StatelessWidget {
  final bool isDark;

  const _HomeAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        10,
        Responsive.horizontalPadding(context),
        5,
      ),
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
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final name = state is ProfileLoaded
                  ? state.profile.fullName?.split(' ').first ?? 'User'
                  : 'User';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EzeeWash',
                    style: GoogleFonts.pacifico(
                      color: Colors.white,
                      fontSize: 26,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hello, $name 👋',
                    style: GoogleFonts.alexandria(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: () => context.go(RoutesName.alerts),
            child: BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final unread = state is NotificationsLoaded
                    ? state.unreadCount
                    : 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Iconsax.notification,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Search Box =====
class _SearchBox extends StatefulWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.isDark, required this.onChanged});

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: GoogleFonts.alexandria(
            color: widget.isDark ? Colors.grey[500] : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[400],
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.grey[400],
                    onPressed: () {
                      _ctrl.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

// ===== Section Header =====
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.alexandria(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'View All',
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== Services Grid (BLoC-driven) =====
class _ServicesGrid extends StatelessWidget {
  final bool isDark;
  final int crossAxisCount;
  final String localQuery;

  const _ServicesGrid({
    required this.isDark,
    required this.crossAxisCount,
    required this.localQuery,
  });

  static const _serviceIcons = [
    Icons.water_drop_outlined,
    Icons.dry_cleaning_outlined,
    Icons.local_fire_department_outlined,
    Icons.flash_on,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      // Only rebuild when the master services list changes — not on
      // service screen filter/search changes which mutate state.filtered
      buildWhen: (prev, curr) {
        if (prev is ServicesLoaded && curr is ServicesLoaded) {
          return prev.services != curr.services;
        }
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        if (state is ServicesLoading) return _buildShimmerGrid();

        if (state is ServicesLoaded) {
          // Always read from the unfiltered master list — never state.filtered
          // which is owned by the service screen's search/category state.
          final q = localQuery.toLowerCase().trim();
          final all = state.services;
          final services =
              (q.isEmpty
                      ? all
                      : all.where((s) {
                          return s.title.toLowerCase().contains(q) ||
                              (s.description?.toLowerCase().contains(q) ??
                                  false) ||
                              s.tags.any((t) => t.toLowerCase().contains(q));
                        }).toList())
                  .take(4)
                  .toList();

          if (services.isEmpty && q.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No services found for "$localQuery"',
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount > 2 ? 0.9 : 0.78,
            ),
            itemCount: services.length,
            itemBuilder: (context, i) {
              final s = services[i];
              return _ServiceCard(
                title: s.title,
                subtitle: s.description ?? '',
                price: s.price.toStringAsFixed(0),
                imageUrl: s.imageUrl,
                fallbackIcon: _serviceIcons[i % _serviceIcons.length],
                isDark: isDark,
                onTap: () =>
                    context.push(RoutesName.placeOrdersNavigate, extra: s.id),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ===== Service Card Widget =====
class _ServiceCard extends StatefulWidget {
  final String title, subtitle, price;
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.imageUrl,
    required this.fallbackIcon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
            boxShadow: widget.isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Service image or fallback icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: widget.imageUrl == null ? AppColors.gradient : null,
                  color: widget.imageUrl != null
                      ? (widget.isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade100)
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.fallbackIcon,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        )
                      : Icon(
                          widget.fallbackIcon,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: widget.isDark ? Colors.white : AppColors.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: GoogleFonts.alexandria(
                  color: widget.isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'From ৳${widget.price}',
                style: GoogleFonts.alexandria(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Quick Actions =====
class _QuickActions extends StatelessWidget {
  final bool isDark;

  const _QuickActions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Book Now',
            icon: Iconsax.calendar_tick,
            filled: true,
            isDark: isDark,
            onTap: () => context.push(RoutesName.placeOrdersNavigate),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _ActionBtn(
            label: 'Track Order',
            icon: Iconsax.truck,
            filled: false,
            isDark: isDark,
            onTap: () => context.push(RoutesName.trackOrdersNavigate),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: filled ? AppColors.gradient : null,
          color: filled
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : AppColors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Recent Orders (BLoC-driven) =====
class _RecentOrdersList extends StatelessWidget {
  final bool isDark;

  const _RecentOrdersList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        // Only show spinner on the very first load (OrdersInitial → OrdersLoading)
        if (state is OrdersInitial || state is OrdersLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state is OrdersLoaded) {
          final recent = state.orders.take(2).toList();
          if (recent.isEmpty) {
            return Center(
              child: Text(
                'No orders yet. Book your first service!',
                style: GoogleFonts.alexandria(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
            );
          }
          return Column(
            children: recent
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecentOrderCard(
                      orderId: order.id,
                      id: '#${order.orderNumber}',
                      service: order.serviceName,
                      status: order.status,
                      progress: order.progress,
                      isDark: isDark,
                      image: order.serviceImageUrl.toString(),
                    ),
                  ),
                )
                .toList(),
          );
        }
        // OrderPlacing / OrderPlaced / OrdersError — show nothing in home
        return const SizedBox.shrink();
      },
    );
  }
}

class _RecentOrderCard extends StatelessWidget {
  final String orderId, id, service, status, image;
  final double progress;
  final bool isDark;

  const _RecentOrderCard({
    required this.orderId,
    required this.id,
    required this.service,
    required this.status,
    required this.progress,
    required this.isDark,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'delivered';
    final statusColor = isCompleted ? AppColors.success : AppColors.warning;
    final statusLabel = status.replaceAll('_', ' ').toUpperCase();

    return GestureDetector(
      onTap: () => context.push(RoutesName.trackOrdersNavigate, extra: orderId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _ServiceImage(isDark: isDark, imageUrl: image),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: GoogleFonts.alexandria(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightText,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        service,
                        style: GoogleFonts.alexandria(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  statusLabel,
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: TrackContent.effectiveProgress(
                  status: status,
                  dbProgress: progress,
                ),
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  isCompleted ? statusColor : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(TrackContent.effectiveProgress(status: status, dbProgress: progress) * 100).toInt()}% Complete',
                style: GoogleFonts.alexandria(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ), // Container
    ); // GestureDetector
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;

  const _ServiceImage({this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        gradient: imageUrl == null ? AppColors.gradient : null,
        color: imageUrl != null
            ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )
            : const Icon(
                Icons.local_laundry_service,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }
}
