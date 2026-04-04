// lib/features/services/presentation/screens/service_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/service_entity.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  static const _categoryIcons = {
    'All Services': Iconsax.category,
    'Wash & Fold': Icons.water_drop_outlined,
    'Dry Clean': Icons.dry_cleaning_outlined,
    'Iron & Press': Icons.local_fire_department_outlined,
    'Express': Icons.flash_on,
    'Steam Clean': Icons.water_outlined,
    'Suit Wash': Icons.style_outlined,
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
      body: Column(
        children: [
          _ServicesAppBar(isDark: isDark),

          Expanded(
            child: BlocBuilder<ServicesBloc, ServicesState>(
              builder: (context, state) {
                if (state is ServicesLoading) {
                  return _ServicesShimmer(isDark: isDark);
                }
                if (state is ServicesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message),
                        TextButton(
                          onPressed: () => context
                              .read<ServicesBloc>()
                              .add(const ServicesLoadRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ServicesLoaded) {
                  return _ServicesContent(
                    state: state,
                    isDark: isDark,
                    categoryIcons: _categoryIcons,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────

class _ServicesShimmer extends StatelessWidget {
  final bool isDark;
  const _ServicesShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          16,
          Responsive.horizontalPadding(context),
          30,
        ),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

// ─── Unified Custom App Bar ───────────────────────────────────────────────────

class _ServicesAppBar extends StatelessWidget {
  final bool isDark;
  const _ServicesAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Our Services',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SearchBar(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Enhanced Search Bar ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final bool isDark;
  const _SearchBar({required this.isDark});

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
        style: GoogleFonts.alexandria(
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.lightText,
        ),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: GoogleFonts.alexandria(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: isDark ? Colors.grey[400] : Colors.grey[400],
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Scrollable Body Content ──────────────────────────────────────────────────

class _ServicesContent extends StatelessWidget {
  final ServicesLoaded state;
  final bool isDark;
  final Map<String, IconData> categoryIcons;

  const _ServicesContent({
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
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        16,
        Responsive.horizontalPadding(context),
        30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = state.selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _CategoryChip(
                        label: cat,
                        icon: categoryIcons[cat] ?? Iconsax.category,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => context
                            .read<ServicesBloc>()
                            .add(ServicesFilterChanged(cat)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              if (state.filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No services found',
                      style: GoogleFonts.alexandria(
                        color: isDark
                            ? AppColors.darkSubtext
                            : AppColors.lightSubtext,
                      ),
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
                  itemBuilder: (context, i) => _ServiceCard(
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

// ─── Category Chip ────────────────────────────────────────────────────────────

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
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
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
              style: GoogleFonts.alexandria(
                fontSize: 13,
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

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;

  const _ServiceCard({required this.service, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: service.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: service.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (_, __, ___) =>
                    _ServiceImageFallback(isDark: isDark),
              )
                  : _ServiceImageFallback(isDark: isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: GoogleFonts.alexandria(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.alexandria(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${service.price.toStringAsFixed(0)}',
                          style: GoogleFonts.alexandria(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          service.duration ?? '',
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: service.tags
                      .map((tag) => _Tag(tag: tag, isDark: isDark))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Iconsax.star,
                            size: 16, color: AppColors.primary),
                        onPressed: () => _ReviewBottomSheet.show(
                            context, service, isDark),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        label: Text(
                          'Reviews',
                          style: GoogleFonts.alexandria(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Iconsax.calendar_tick,
                              color: Colors.white, size: 16),
                          onPressed: () => context.push(
                              RoutesName.placeOrdersNavigate,
                              extra: service.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          label: Text(
                            'Book Now',
                            style: GoogleFonts.alexandria(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String tag;
  final bool isDark;

  const _Tag({required this.tag, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withOpacity(0.2)
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: GoogleFonts.alexandria(
          color: isDark ? Colors.blue.shade300 : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Fallback when imageUrl is null or fails to load ─────────────────────────

class _ServiceImageFallback extends StatelessWidget {
  final bool isDark;
  const _ServiceImageFallback({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? AppColors.primary.withOpacity(0.15)
          : AppColors.primary.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.local_laundry_service_rounded,
          size: 56,
          color: AppColors.primary.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEW SYSTEM (VIEW ONLY)
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Data model ───────────────────────────────────────────────────────────────

class _Review {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const _Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory _Review.fromJson(Map<String, dynamic> j) {
    final profile = j['profiles'] as Map<String, dynamic>?;
    return _Review(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      userName: profile?['full_name'] as String? ??
          profile?['email'] as String? ??
          'Anonymous',
      userAvatar: profile?['avatar_url'] as String?,
      rating: (j['rating'] as num).toDouble(),
      comment: j['comment'] as String? ?? '',
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

// ─── Entry point ──────────────────────────────────────────────────────────────

class _ReviewBottomSheet {
  static void show(BuildContext context, ServiceEntity service, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => _ReviewSheet(
        service: service,
        isDark: isDark,
      ),
    );
  }
}

// ─── Main sheet ───────────────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final ServiceEntity service;
  final bool isDark;
  const _ReviewSheet({
    required this.service,
    required this.isDark,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _client = Supabase.instance.client;

  List<_Review> _reviews = [];
  bool _loading = true;
  String? _error;
  double _avg = 0;
  Map<int, int> _dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _client
          .from(AppConstants.reviewsTable)
          .select('*, profiles(full_name, avatar_url, email)')
          .eq('service_id', widget.service.id)
          .order('created_at', ascending: false);

      final reviews = (data as List).map((e) => _Review.fromJson(e)).toList();
      final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double sum = 0;
      for (final r in reviews) {
        dist[r.rating.round().clamp(1, 5)] =
            (dist[r.rating.round().clamp(1, 5)] ?? 0) + 1;
        sum += r.rating;
      }
      setState(() {
        _reviews = reviews;
        _dist = dist;
        _avg = reviews.isEmpty ? 0 : sum / reviews.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.darkSurface : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.35,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.52, 0.88],
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            AppSheetHandle(isDark: widget.isDark),
            _SheetHeader(
              service: widget.service,
              isDark: widget.isDark,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5))
                  : _error != null
                  ? _ErrorState(
                  message: _error!,
                  onRetry: _load,
                  isDark: widget.isDark)
                  : CustomScrollView(
                controller: scrollCtrl,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryBar(
                            avg: _avg,
                            count: _reviews.length,
                            dist: _dist,
                            isDark: widget.isDark,
                          ),
                          const SizedBox(height: 20),
                          if (_reviews.isNotEmpty) ...[
                            AppSectionLabel(
                              text:
                              '${_reviews.length} Review${_reviews.length == 1 ? '' : 's'}',
                              isDark: widget.isDark,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _reviews.isEmpty
                      ? SliverFillRemaining(
                      child: AppEmptyState(message: 'No reviews yet.', isDark: widget.isDark))
                      : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _ReviewTile(
                          review: _reviews[i],
                          isDark: widget.isDark,
                          showDivider: i < _reviews.length - 1,
                        ),
                        childCount: _reviews.length,
                      ),
                    ),
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

// ─── Summary bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double avg;
  final int count;
  final Map<int, int> dist;
  final bool isDark;

  const _SummaryBar({
    required this.avg,
    required this.count,
    required this.dist,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF0F5FF);

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Text('No reviews yet for this service.',
              style: GoogleFonts.alexandria(
                  fontSize: 13,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.gradient.createShader(b),
            child: Text(
              avg.toStringAsFixed(1),
              style: GoogleFonts.alexandria(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          _StarRow(rating: avg, size: 14),
          const SizedBox(height: 2),
          Text(
            '$count review${count == 1 ? '' : 's'}',
            style: GoogleFonts.alexandria(
                fontSize: 10,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ]),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 1,
          height: 60,
          color: AppColors.primary.withOpacity(0.15),
        ),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final n = dist[star] ?? 0;
              final frac = count == 0 ? 0.0 : n / count;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(children: [
                  Text('$star',
                      style: GoogleFonts.alexandria(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext)),
                  const SizedBox(width: 3),
                  const Icon(Icons.star_rounded,
                      size: 10, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: frac),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.black.withOpacity(0.06),
                          valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 16,
                    child: Text('$n',
                        style: GoogleFonts.alexandria(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext)),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Review tile ──────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final _Review review;
  final bool isDark, showDivider;

  const _ReviewTile({
    required this.review,
    required this.isDark,
    required this.showDivider,
  });

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 365) return '${(d.inDays / 365).floor()}y ago';
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()}mo ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final initials =
    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.gradient),
              child: review.userAvatar != null
                  ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: review.userAvatar!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                        child: Text(initials,
                            style: GoogleFonts.alexandria(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15))),
                  ))
                  : Center(
                  child: Text(initials,
                      style: GoogleFonts.alexandria(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review.userName,
                              style: GoogleFonts.alexandria(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightText)),
                          Text(_ago(review.createdAt),
                              style: GoogleFonts.alexandria(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext)),
                        ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      _StarRow(rating: review.rating, size: 13),
                      const SizedBox(width: 5),
                      Text(review.rating.toStringAsFixed(1),
                          style: GoogleFonts.alexandria(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFBBF24))),
                    ]),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(review.comment,
                          style: GoogleFonts.alexandria(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                              height: 1.5)),
                    ],
                  ]),
            ),
          ]),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ],
    );
  }
}

// ─── Star row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating && (rating - rating.floor()) >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xFFFBBF24),
          size: size,
        );
      }),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState(
      {required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 44),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.alexandria(
                color: AppColors.error, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Text('Retry',
              style: GoogleFonts.alexandria(color: Colors.white)),
        ),
      ]),
    ),
  );
}

// ─── Sheet header ─────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;
  final VoidCallback onClose;

  const _SheetHeader(
      {required this.service, required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.star_1, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service.title,
                  style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.lightText)),
              Text('Customer Reviews',
                  style: GoogleFonts.alexandria(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext)),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: isDark ? Colors.white38 : Colors.black38, size: 22),
            onPressed: onClose,
          ),
        ]),
      ),
      Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    ]);
  }
}