// ignore_for_file: use_build_context_synchronously
// lib/features/home/presentation/screens/home_screen.dart
//
// Refactored: AppSnackBar replaces inline SnackBar construction.

import 'package:ezzewash/features/promos/presentation/screen/promo_banner.dart';
import 'package:flutter/material.dart';
import '../../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../../features/profile/presentation/bloc/profile_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../routes/routes_name.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../promos/presentation/bloc/promo_bloc.dart';
import '../../../promos/presentation/bloc/promo_event.dart';
import '../../../promos/presentation/bloc/promo_state.dart';
import '../../../services/presentation/bloc/service_bloc.dart';
import '../../../services/presentation/bloc/service_event.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.fromSignUp) {
        AppSnackBar.show(context, 'Account created successfully! Welcome 🎉');
      }
      _checkAndShowUpdateDialog();
    });
  }

  Future<void> _checkAndShowUpdateDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final uri = Uri.parse(
        'https://api.github.com/repos/Abdulaowalasif/ezze-wash-apk-release/releases?per_page=10&page=1',
      );
      final githubToken = dotenv.env['GITHUB_PAT'] ?? '';

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'EzeeWash-App',
              if (githubToken.isNotEmpty)
                'Authorization': 'Bearer $githubToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;
        String? latestVersion;
        String? apkUrl;

        for (final r in releases) {
          final release = r as Map<String, dynamic>;
          final assets = (release['assets'] as List?) ?? [];
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['url'] as String?;
              latestVersion = (release['tag_name'] as String? ?? '').replaceAll(
                'v',
                '',
              );
              break;
            }
          }
          if (apkUrl != null) break;
        }

        if (latestVersion != null && apkUrl != null) {
          final lastPrompted = prefs.getString('last_prompted_version');
          if (latestVersion == lastPrompted) return;

          final cleanLatest = latestVersion.replaceAll(RegExp(r'[^0-9.]'), '');
          final cleanCurrent = currentVersion.replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          );

          bool isNewer = false;
          final l = cleanLatest
              .split('.')
              .where((e) => e.isNotEmpty)
              .map((e) => int.tryParse(e) ?? 0)
              .toList();
          final c = cleanCurrent
              .split('.')
              .where((e) => e.isNotEmpty)
              .map((e) => int.tryParse(e) ?? 0)
              .toList();
          final maxLen = l.length > c.length ? l.length : c.length;
          for (int i = 0; i < maxLen; i++) {
            final lv = i < l.length ? l[i] : 0;
            final cv = i < c.length ? c[i] : 0;
            if (lv > cv) {
              isNewer = true;
              break;
            }
            if (lv < cv) break;
          }

          if (isNewer && context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                final isDark = Theme.of(ctx).brightness == Brightness.dark;
                return AlertDialog(
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  title: Text(
                    'Update Available',
                    style: AppTextStyles.h4(isDark),
                  ),
                  content: Text(
                    'A new version ($latestVersion) is available. Would you like to update now?',
                    style: AppTextStyles.body(isDark),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await prefs.setString(
                          'last_prompted_version',
                          latestVersion!,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Not Now',
                        style: AppTextStyles.buttonOutline,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await prefs.setString(
                          'last_prompted_version',
                          latestVersion!,
                        );
                        if (ctx.mounted && context.mounted) {
                          Navigator.pop(ctx);
                          context.push(
                            RoutesName.settingsNavigate,
                            extra: true,
                          );
                        }
                      },
                      child: const Text(
                        'Update Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
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
                      // Promo Section now manages its own bottom spacing
                      HomePromoSection(isDark: isDark),

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
                      const SizedBox(height: 16),
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
          // Use the custom shimmer we created earlier, and add the spacing here
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppShimmer.promoBanner(isDark: isDark),
          );
        } else if (state is PromoLoaded) {
          final now = DateTime.now();
          final validPromos = state.promos.where((p) {
            if (!p.isActive) return false;
            if (p.validUntil != null && p.validUntil!.isBefore(now)) {
              return false;
            }
            return true;
          }).toList();

          if (validPromos.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PromoBannerSlider(promos: validPromos, isDark: isDark),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
