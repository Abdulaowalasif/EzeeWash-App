// lib/core/widgets/app_shimmer_list.dart
//
// A vertical shimmer skeleton list — replaces the copy-pasted shimmer
// Column + ListView pattern found in order_screen, service_screen, etc.
//
// Usage:
//   AppShimmerList(isDark: isDark, itemHeight: 160, itemCount: 4)
//   AppShimmerList(isDark: isDark, itemHeight: 90, itemCount: 6, topWidget: _toggle)

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'app_shimmer_box.dart';

class AppShimmerList extends StatelessWidget {
  final bool isDark;
  final double itemHeight;
  final int itemCount;
  final double itemRadius;
  final double itemSpacing;

  /// Optional widget rendered above the list (e.g. a toggle or header).
  final Widget? topWidget;

  const AppShimmerList({
    super.key,
    required this.isDark,
    required this.itemHeight,
    this.itemCount = 4,
    this.itemRadius = 24,
    this.itemSpacing = 16,
    this.topWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppShimmerColors.base(isDark),
      highlightColor: AppShimmerColors.highlight(isDark),
      child: Column(
        children: [
          if (topWidget != null) ...[
            topWidget!,
            SizedBox(height: itemSpacing),
          ],
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(height: itemSpacing),
              itemBuilder: (_, _) => AppShimmerBox(
                height: itemHeight,
                radius: itemRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
