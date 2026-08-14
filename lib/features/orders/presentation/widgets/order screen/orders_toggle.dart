import 'package:flutter/material.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/theme/app_text_styles.dart';

class OrdersToggle extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final PageController pageController;

  const OrdersToggle({
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
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          // ─── Sliding Selection Background ───
          AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              // Default to state value if controller isn't ready
              double page = showActive ? 0.0 : 1.0;

              if (pageController.hasClients &&
                  pageController.position.haveDimensions) {
                page = pageController.page ?? page;
              }

              // Clamp to ensure it stays within bounds during overscroll
              page = page.clamp(0.0, 1.0);

              // Math: 0.0 (active) maps to -1.0 alignment, 1.0 (history) maps to 1.0 alignment
              final alignmentX = (page * 2) - 1.0;

              return Align(
                alignment: Alignment(alignmentX, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
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
                      child: const Text('Active Orders'),
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
                      child: const Text('Order History'),
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
