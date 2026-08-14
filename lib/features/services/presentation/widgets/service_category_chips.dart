// lib/features/services/presentation/widgets/service_category_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';

class ServiceCategoryChips extends StatelessWidget {
  final ServicesLoaded state;
  final bool isDark;
  final Map<String, IconData> categoryIcons;

  const ServiceCategoryChips({
    super.key,
    required this.state,
    required this.isDark,
    required this.categoryIcons,
  });

  List<String> get _categories {
    final cats = state.services.map((s) => s.category).toSet().toList();
    return ['All Services', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = state.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _CategoryChip(
              label: cat,
              icon: categoryIcons[cat] ?? Icons.category_outlined,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () =>
                  context.read<ServicesBloc>().add(ServicesFilterChanged(cat)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.gradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1.2,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.gridTitle(isDark).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
