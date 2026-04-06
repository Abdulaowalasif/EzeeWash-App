// lib/features/services/presentation/screens/service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_shimmer_box.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import '../widgets/service_widgets.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  static const _categoryIcons = <String, IconData>{
    'All Services': Iconsax.category,
    'Wash & Fold':  Icons.water_drop_outlined,
    'Dry Clean':    Icons.dry_cleaning_outlined,
    'Iron & Press': Icons.local_fire_department_outlined,
    'Express':      Icons.flash_on,
    'Steam Clean':  Icons.water_outlined,
    'Suit Wash':    Icons.style_outlined,
  };

  @override
  void dispose() {
    final bloc = context.read<ServicesBloc>();
    if (bloc.state is ServicesLoaded) {
      bloc.add(const ServicesFilterChanged('All Services'));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const GradientAppBar(
        title: 'Our Services',
        backEnabled: false,
      ),
      body: BlocBuilder<ServicesBloc, ServicesState>(
        builder: (context, state) {
          if (state is ServicesLoading) {
            return _ServiceLoadingBody(isDark: isDark);
          }
          if (state is ServicesError) {
            return _ServiceErrorBody(message: state.message, isDark: isDark);
          }
          if (state is ServicesLoaded) {
            return _ServiceLoadedBody(
              state: state,
              isDark: isDark,
              categoryIcons: _categoryIcons,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _ServiceLoadingBody extends StatelessWidget {
  final bool isDark;
  const _ServiceLoadingBody({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context), 16,
            Responsive.horizontalPadding(context), 0,
          ),
          child: ServiceSearchBar(isDark: isDark),
        ),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: AppShimmerColors.base(isDark),
            highlightColor: AppShimmerColors.highlight(isDark),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context), 16,
                Responsive.horizontalPadding(context), 30,
              ),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, __) =>
              const AppShimmerBox(height: 280, radius: 24),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ServiceErrorBody extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ServiceErrorBody({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context), 16,
            Responsive.horizontalPadding(context), 0,
          ),
          child: ServiceSearchBar(isDark: isDark),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(message, style: AppTextStyles.caption(isDark)),
                TextButton(
                  onPressed: () => context
                      .read<ServicesBloc>()
                      .add(const ServicesLoadRequested()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loaded body ──────────────────────────────────────────────────────────────

class _ServiceLoadedBody extends StatelessWidget {
  final ServicesLoaded state;
  final bool isDark;
  final Map<String, IconData> categoryIcons;

  const _ServiceLoadedBody({
    required this.state,
    required this.isDark,
    required this.categoryIcons,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context), 16,
        Responsive.horizontalPadding(context), 30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceSearchBar(isDark: isDark),
              const SizedBox(height: 16),
              ServiceCategoryChips(
                state: state,
                isDark: isDark,
                categoryIcons: categoryIcons,
              ),
              const SizedBox(height: 20),
              if (state.filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No services found',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: state.filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => ServiceCard(
                    service: state.filtered[i],
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}