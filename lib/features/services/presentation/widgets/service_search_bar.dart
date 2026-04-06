// lib/features/services/presentation/widgets/service_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';

class ServiceSearchBar extends StatelessWidget {
  final bool isDark;
  const ServiceSearchBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextField(
        onChanged: (val) =>
            context.read<ServicesBloc>().add(ServicesSearchChanged(val)),
        style: AppTextStyles.body(isDark),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: AppTextStyles.hint(isDark),
          prefixIcon: Icon(Iconsax.search_normal,
              color: Colors.grey[400], size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 20),
        ),
      ),
    );
  }
}
