// lib/features/services/presentation/widgets/service_review_sheet.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/service_remote_datasource.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/service_entity.dart';

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
      userName:
          profile?['full_name'] as String? ??
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

class ServiceReviewSheet {
  ServiceReviewSheet._();

  static void show(BuildContext context, ServiceEntity service, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => _ReviewSheet(service: service, isDark: isDark),
    );
  }
}

// ─── Sheet StatefulWidget ─────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final ServiceEntity service;
  final bool isDark;

  const _ReviewSheet({required this.service, required this.isDark});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
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
      final data = await sl<ServicesRemoteDataSource>()
          .getServiceReviews(widget.service.id);

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
              color: Colors.black.withValues(alpha: 0.18),
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
                  ? const AppLoadingIndicator()
                  : _error != null
                  ? _ErrorState(
                      message: _error!,
                      onRetry: _load,
                      isDark: widget.isDark,
                    )
                  : _ReviewListView(
                      reviews: _reviews,
                      avg: _avg,
                      dist: _dist,
                      isDark: widget.isDark,
                      scrollCtrl: scrollCtrl,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review list ──────────────────────────────────────────────────────────────

class _ReviewListView extends StatelessWidget {
  final List<_Review> reviews;
  final double avg;
  final Map<int, int> dist;
  final bool isDark;
  final ScrollController scrollCtrl;

  const _ReviewListView({
    required this.reviews,
    required this.avg,
    required this.dist,
    required this.isDark,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReviewSummaryBar(
                  avg: avg,
                  count: reviews.length,
                  dist: dist,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                if (reviews.isNotEmpty) ...[
                  AppSectionLabel(
                    text:
                        '${reviews.length} Review${reviews.length == 1 ? '' : 's'}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        reviews.isEmpty
            ? SliverFillRemaining(
                child: AppEmptyState(
                  message: 'No reviews yet.',
                  isDark: isDark,
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ReviewTile(
                      review: reviews[i],
                      isDark: isDark,
                      showDivider: i < reviews.length - 1,
                    ),
                    childCount: reviews.length,
                  ),
                ),
              ),
      ],
    );
  }
}

// ─── Summary bar ──────────────────────────────────────────────────────────────

class _ReviewSummaryBar extends StatelessWidget {
  final double avg;
  final int count;
  final Map<int, int> dist;
  final bool isDark;

  const _ReviewSummaryBar({
    required this.avg,
    required this.count,
    required this.dist,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.primary.withValues(alpha: 0.08)
        : const Color(0xFFF0F5FF);

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'No reviews yet for this service.',
              style: AppTextStyles.caption(isDark),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big average score
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.gradient.createShader(b),
                child: Text(
                  avg.toStringAsFixed(1),
                  style: AppTextStyles.heading(
                    isDark,
                  ).copyWith(fontSize: 38, color: Colors.white),
                ),
              ),
              AppRatingStars(rating: avg, size: 14),
              const SizedBox(height: 2),
              Text(
                '$count review${count == 1 ? '' : 's'}',
                style: AppTextStyles.tiny(isDark),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 60,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          // Per-star distribution
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final n = dist[star] ?? 0;
                final frac = count == 0 ? 0.0 : n / count;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      Text('$star', style: AppTextStyles.captionMedium(isDark)),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.star_rounded,
                        size: 10,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: frac),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 16,
                        child: Text('$n', style: AppTextStyles.tiny(isDark)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review tile ──────────────────────────────────────────────────────────────

class _ReviewTile extends StatelessWidget {
  final _Review review;
  final bool isDark;
  final bool showDivider;

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
    final initials = review.userName.isNotEmpty
        ? review.userName[0].toUpperCase()
        : '?';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradient,
                ),
                child: review.userAvatar != null
                    ? ClipOval(
                        child: AppNetworkImage(
                          url: review.userAvatar,
                          width: 38,
                          height: 38,
                          radius: 19,
                          isDark: isDark,
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.onGradientTitle.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.userName,
                          style: AppTextStyles.gridTitle(isDark),
                        ),
                        Text(
                          _ago(review.createdAt),
                          style: AppTextStyles.caption(isDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        AppRatingStars(rating: review.rating, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: AppTextStyles.rating,
                        ),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        review.comment,
                        style: AppTextStyles.bodyLong(isDark),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      ],
    );
  }
}

// ─── Sheet header ─────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final ServiceEntity service;
  final bool isDark;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.service,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.star_1,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.title, style: AppTextStyles.cardTitle(isDark)),
                    Text(
                      'Customer Reviews',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 22,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(
              isDark,
            ).copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Retry', style: AppTextStyles.button),
          ),
        ],
      ),
    ),
  );
}
