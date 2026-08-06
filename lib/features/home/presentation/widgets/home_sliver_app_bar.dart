// lib/features/home/presentation/widgets/home_sliver_app_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../routes/routes_name.dart';
import 'home_search_box.dart';
import 'home_profile_glass_card.dart';

class HomeSliverAppBar extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onSearch;

  const HomeSliverAppBar({
    super.key,
    required this.isDark,
    required this.onSearch,
  });

  static const double _expandedHeight = 245.0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final minHeight = kToolbarHeight + statusBarHeight;

          final percent =
          ((top - minHeight) / (_expandedHeight - minHeight)).clamp(0.0, 1.0);

          final titleCollapsedTop =
              statusBarHeight + (kToolbarHeight - 40) / 2;
          final titleExpandedTop = statusBarHeight + 16.0;
          final currentTitleTop =
              titleCollapsedTop + (titleExpandedTop - titleCollapsedTop) * percent;

          final currentScale = 1.0 + (0.35 * percent);

          return Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              
            ),
            child: Stack(
              children: [
                // Profile card + search box fade in as bar expands
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Opacity(
                    opacity: percent,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - percent)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                context.push(RoutesName.settingsNavigate),
                            child: const HomeProfileGlassCard(),
                          ),
                          const SizedBox(height: 16),
                          HomeSearchBox(isDark: isDark, onChanged: onSearch),
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated logo
                Positioned(
                  left: 20,
                  top: currentTitleTop,
                  child: Transform.scale(
                    scale: currentScale,
                    alignment: Alignment.topLeft,
                    child: Text('Ezze Wash', style: AppTextStyles.brandLogo),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}