// lib/core/widgets/app_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ─── Palette (backwards-compatible) ───────────────────────────────────────────

class AppShimmerColors {
  AppShimmerColors._();

  static Color base(bool isDark) =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0);

  static Color highlight(bool isDark) =>
      isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF8FAFC);
}

// ─── Primitives ────────────────────────────────────────────────────────────────

/// Filled rounded rectangle.
/// Place inside a [Shimmer.fromColors] or inside [AppShimmer.custom].
class AppShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const AppShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Circle placeholder — for avatars, icon boxes, status dots.
class AppShimmerCircle extends StatelessWidget {
  final double size;

  const AppShimmerCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// Thin rounded rectangle — for text lines.
class AppShimmerLine extends StatelessWidget {
  final double? width;
  final double height;

  const AppShimmerLine({super.key, this.width, this.height = 13});

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

// ─── AppShimmer ────────────────────────────────────────────────────────────────

class AppShimmer extends StatelessWidget {
  final _ShimmerKind _kind;
  final bool isDark;
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  // ── serviceGrid ─────────────────────────────────────────────────────────────
  // Matches HomeServiceCard & service screen grid:
  //   circle(60) → title line → subtitle line → price line

  const AppShimmer.serviceGrid({
    super.key,
    required this.isDark,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.78,
    this.itemCount = 4,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.serviceGrid,
       child = null;

  // ── recentOrderList ─────────────────────────────────────────────────────────
  // Matches RecentOrderCard (AppCard, padding:16, radius:18):
  //   image(54×54,r14) + order# + service name + status badge + progress bar

  const AppShimmer.recentOrderList({
    super.key,
    required this.isDark,
    this.itemCount = 2,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.recentOrderList,
       crossAxisCount = 2,
       childAspectRatio = 1,
       child = null;

  // ── orderList ───────────────────────────────────────────────────────────────
  // Matches OrderCard in the Orders screen (AppCard, padding:20, radius:20):
  //   toggle bar(h44,r14) → cards: image(52×52) + text + progress + 2 buttons

  const AppShimmer.orderList({
    super.key,
    required this.isDark,
    this.itemCount = 4,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.orderList,
       crossAxisCount = 2,
       childAspectRatio = 1,
       child = null;

  // ── notificationList ────────────────────────────────────────────────────────
  // Matches NotificationCard (padding:16, radius:18):
  //   icon-box(40×40,r12) + title + body lines + timestamp + track badge

  const AppShimmer.notificationList({
    super.key,
    required this.isDark,
    this.itemCount = 6,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.notificationList,
       crossAxisCount = 2,
       childAspectRatio = 1,
       child = null;

  // ── serviceList ─────────────────────────────────────────────────────────────
  // Matches ServiceCard full-width list (AppCard, padding:zero):
  //   hero image(140h, top-radius 24) → header row → tags → action buttons

  const AppShimmer.serviceList({
    super.key,
    required this.isDark,
    this.itemCount = 3,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.serviceList,
       crossAxisCount = 2,
       childAspectRatio = 1,
       child = null;


  const AppShimmer.promoBanner({
    super.key,
    required this.isDark,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  })  : _kind = _ShimmerKind.promoBanner,
        itemCount = 1,
        crossAxisCount = 1,
        childAspectRatio = 1,
        child = null;

  // ── profileGlassCard ────────────────────────────────────────────────────────
  // Matches _GlassCardShimmer — white-on-glass palette (no isDark needed)

  const AppShimmer.profileGlassCard({super.key})
    : _kind = _ShimmerKind.profileGlassCard,
      isDark = false,
      crossAxisCount = 2,
      childAspectRatio = 1,
      itemCount = 1,
      padding = EdgeInsets.zero,
      child = null;

  // ── custom ──────────────────────────────────────────────────────────────────
  // Wrap your own skeleton widgets in the shimmer animation

  const AppShimmer.custom({
    super.key,
    required this.isDark,
    required Widget this.child,
    this.padding = EdgeInsets.zero,
  }) : _kind = _ShimmerKind.custom,
       crossAxisCount = 2,
       childAspectRatio = 1,
       itemCount = 1;

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Glass card uses its own shimmer palette
    if (_kind == _ShimmerKind.profileGlassCard) {
      return Shimmer.fromColors(
        baseColor: Colors.white24,
        highlightColor: Colors.white60,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: AppShimmerColors.base(isDark),
      highlightColor: AppShimmerColors.highlight(isDark),
      child: Padding(padding: padding, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_kind) {
      case _ShimmerKind.serviceGrid:
        return _ServiceGridBody(
          itemCount: itemCount,
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
        );
      case _ShimmerKind.recentOrderList:
        return _RecentOrderListBody(itemCount: itemCount);
      case _ShimmerKind.orderList:
        return _OrderListBody(itemCount: itemCount);
      case _ShimmerKind.notificationList:
        return _NotificationListBody(itemCount: itemCount);
      case _ShimmerKind.serviceList:
        return _ServiceListBody(itemCount: itemCount);
      case _ShimmerKind.promoBanner:
        return const _PromoBannerBody();
      case _ShimmerKind.custom:
        return child!;
      case _ShimmerKind.profileGlassCard:
        return const SizedBox.shrink(); // handled above
    }
  }
}

// ─── Promo banner ─────────────────────────────────────────────────────────────

class _PromoBannerBody extends StatelessWidget {
  const _PromoBannerBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Headline (Discount/Code)
                const AppShimmerLine(width: 180, height: 20),
                const SizedBox(height: 12),
                // Description line 1
                const AppShimmerLine(height: 14),
                const SizedBox(height: 6),
                // Description line 2
                AppShimmerLine(width: 120, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Icon placeholder
          const AppShimmerBox(height: 50, width: 50, radius: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Skeleton body widgets (private)
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Service grid ──────────────────────────────────────────────────────────────

class _ServiceGridBody extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;

  const _ServiceGridBody({
    required this.itemCount,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppShimmerCircle(size: 60),
            const SizedBox(height: 10),
            const AppShimmerLine(height: 14),
            const SizedBox(height: 7),
            AppShimmerLine(width: 80, height: 11),
            const SizedBox(height: 8),
            AppShimmerLine(width: 56, height: 11),
          ],
        ),
      ),
    );
  }
}

// ─── Recent order list ─────────────────────────────────────────────────────────

class _RecentOrderListBody extends StatelessWidget {
  final int itemCount;

  const _RecentOrderListBody({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AppShimmerBox(height: 54, width: 54, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmerLine(width: 100, height: 13),
                      const SizedBox(height: 6),
                      const AppShimmerLine(height: 13),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AppShimmerBox(height: 24, width: 72, radius: 20),
              ],
            ),
            const SizedBox(height: 14),
            AppShimmerBox(height: 6, radius: 10),
          ],
        ),
      ),
    );
  }
}

// ─── Full order list ───────────────────────────────────────────────────────────

class _OrderListBody extends StatelessWidget {
  final int itemCount;

  const _OrderListBody({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle bar (Active / History)
        AppShimmerBox(height: 44, radius: 14),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: service image + text block + price
                Row(
                  children: [
                    AppShimmerBox(height: 52, width: 52, radius: 14),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppShimmerLine(height: 15),
                          const SizedBox(height: 5),
                          AppShimmerLine(width: 140, height: 12),
                          const SizedBox(height: 6),
                          AppShimmerLine(width: 90, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppShimmerLine(width: 56, height: 16),
                        const SizedBox(height: 5),
                        AppShimmerLine(width: 36, height: 11),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                AppShimmerBox(height: 6, radius: 10),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(child: AppShimmerBox(height: 40, radius: 12)),
                    const SizedBox(width: 12),
                    Expanded(child: AppShimmerBox(height: 40, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Notification list ─────────────────────────────────────────────────────────

class _NotificationListBody extends StatelessWidget {
  final int itemCount;

  const _NotificationListBody({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box (matches AppIconBox size in NotificationCard)
            AppShimmerBox(height: 40, width: 40, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + unread dot
                  Row(
                    children: [
                      Expanded(child: AppShimmerLine(height: 15)),
                      const SizedBox(width: 8),
                      const AppShimmerCircle(size: 8),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const AppShimmerLine(height: 12),
                  const SizedBox(height: 4),
                  const AppShimmerLine(height: 12),
                  const SizedBox(height: 8),
                  // Timestamp + "Track order" badge
                  Row(
                    children: [
                      AppShimmerLine(width: 60, height: 11),
                      const SizedBox(width: 8),
                      AppShimmerBox(height: 22, width: 80, radius: 6),
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
}

// ─── Service list ──────────────────────────────────────────────────────────────

class _ServiceListBody extends StatelessWidget {
  final int itemCount;

  const _ServiceListBody({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image area (matches _ServiceHeroImage height:140)
            AppShimmerBox(height: 140, radius: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: title + price
                  Row(
                    children: [
                      Expanded(child: AppShimmerLine(height: 17)),
                      const SizedBox(width: 8),
                      AppShimmerLine(width: 60, height: 17),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppShimmerLine(height: 13),
                  const SizedBox(height: 12),
                  // Tags row — 3 chips (matches _ServiceTags)
                  Row(
                    children: [
                      AppShimmerBox(height: 26, width: 70, radius: 20),
                      const SizedBox(width: 8),
                      AppShimmerBox(height: 26, width: 80, radius: 20),
                      const SizedBox(width: 8),
                      AppShimmerBox(height: 26, width: 60, radius: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons (matches _ServiceActions)
                  Row(
                    children: [
                      Expanded(child: AppShimmerBox(height: 44, radius: 14)),
                      const SizedBox(width: 12),
                      Expanded(child: AppShimmerBox(height: 44, radius: 14)),
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
}

// ─── Settings page ─────────────────────────────────────────────────────────────

class _SettingsPageBody extends StatelessWidget {
  const _SettingsPageBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Profile card: avatar circle + name + phone + edit button
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const AppShimmerCircle(size: 70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppShimmerLine(height: 17),
                      const SizedBox(height: 8),
                      AppShimmerLine(width: 140, height: 13),
                      const SizedBox(height: 7),
                      AppShimmerLine(width: 100, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppShimmerBox(height: 36, width: 36, radius: 12),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Info section card
          AppShimmerBox(height: 160, radius: 24),
          const SizedBox(height: 20),
          // Menu section card — 5 rows (icon + label + chevron)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < 4 ? 18 : 0),
                  child: Row(
                    children: [
                      AppShimmerBox(height: 36, width: 36, radius: 10),
                      const SizedBox(width: 14),
                      Expanded(child: AppShimmerLine(height: 14)),
                      const SizedBox(width: 12),
                      AppShimmerBox(height: 20, width: 20, radius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Actions / danger zone card
          AppShimmerBox(height: 130, radius: 24),
        ],
      ),
    );
  }
}

// ─── Enum ──────────────────────────────────────────────────────────────────────

enum _ShimmerKind {
  serviceGrid,
  recentOrderList,
  orderList,
  notificationList,
  serviceList,
  profileGlassCard,
  custom,
  promoBanner,
}
