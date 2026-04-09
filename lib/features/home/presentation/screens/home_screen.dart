// lib/features/home/presentation/screens/home_screen.dart
//
// Refactored: AppSnackBar replaces inline SnackBar construction.

import 'package:ezzewash/features/promos/presentation/screen/promo_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../routes/routes_name.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../promos/presentation/bloc/promo_bloc.dart';
import '../../../promos/presentation/bloc/promo_event.dart';
import '../../../promos/presentation/bloc/promo_state.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchQuery = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<PromoBloc>().add(WatchPromosStarted());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.fromSignUp) {
        AppSnackBar.show(context, 'Account created successfully! Welcome 🎉');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeSliverAppBar(
            isDark: isDark,
            onSearch: (q) => _searchQuery.value = q,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomePromoSection(isDark: isDark),

                      const SizedBox(height: 10),

                      AppSectionHeader(
                        title: 'Our Top Services',
                        onViewAll: () => context.go(RoutesName.services),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 15),
                      ValueListenableBuilder<String>(
                        valueListenable: _searchQuery,
                        builder: (_, query, _) => HomeServicesGrid(
                          isDark: isDark,
                          crossAxisCount: Responsive.gridCount(context),
                          localQuery: query,
                        ),
                      ),
                      const SizedBox(height: 30),
                      HomeQuickActions(isDark: isDark),
                      const SizedBox(height: 30),
                      AppSectionHeader(
                        title: 'Recent Orders',
                        onViewAll: () => context.go(RoutesName.orders),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 15),
                      HomeRecentOrders(isDark: isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/features/home/presentation/widgets/home_promo_section.dart

class HomePromoSection extends StatelessWidget {
  final bool isDark;

  const HomePromoSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromoBloc, PromoState>(
      builder: (context, state) {
        if (state is PromoLoading) {
          // Use the custom shimmer we created earlier
          return AppShimmer.promoBanner(isDark: isDark);
        } else if (state is PromoLoaded) {
          final activePromos = state.promos.where((p) => p.isActive).toList();
          if (activePromos.isEmpty) return const SizedBox.shrink();

          return PromoBannerSlider(promos: activePromos, isDark: isDark);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
