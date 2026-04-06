// lib/features/orders/presentation/screens/order_screen.dart
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/order_status.dart';
import '../../../../core/utils/business_utils_logic.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../screens/place_order_screen.dart' show ReorderParams;

// ─── Filter model ─────────────────────────────────────────────────────────────

enum _DateRange { all, today, last7, last30, custom }

class _OrderFilter {
  final _DateRange dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? storeId;
  final String? serviceName;
  final String? status;
  final String? sortBy;

  const _OrderFilter({
    this.dateRange = _DateRange.all,
    this.customStart,
    this.customEnd,
    this.storeId,
    this.serviceName,
    this.status,
    this.sortBy = 'newest',
  });

  bool get isActive =>
      dateRange != _DateRange.all ||
          storeId != null ||
          serviceName != null ||
          status != null ||
          (sortBy != 'newest');

  int get activeCount {
    int c = 0;
    if (dateRange != _DateRange.all) c++;
    if (storeId != null) c++;
    if (serviceName != null) c++;
    if (status != null) c++;
    if (sortBy != 'newest') c++;
    return c;
  }

  _OrderFilter copyWith({
    _DateRange? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    Object? storeId = _sentinel,
    Object? serviceName = _sentinel,
    Object? status = _sentinel,
    String? sortBy,
  }) {
    return _OrderFilter(
      dateRange: dateRange ?? this.dateRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      storeId: storeId == _sentinel ? this.storeId : storeId as String?,
      serviceName:
      serviceName == _sentinel ? this.serviceName : serviceName as String?,
      status: status == _sentinel ? this.status : status as String?,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<OrderEntity> apply(List<OrderEntity> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var result = orders.where((o) {
      if (dateRange != _DateRange.all) {
        final d = o.createdAt;
        switch (dateRange) {
          case _DateRange.today:
            if (d.isBefore(today)) return false;
            break;
          case _DateRange.last7:
            if (d.isBefore(today.subtract(const Duration(days: 7)))) return false;
            break;
          case _DateRange.last30:
            if (d.isBefore(today.subtract(const Duration(days: 30)))) return false;
            break;
          case _DateRange.custom:
            if (customStart != null && d.isBefore(customStart!)) return false;
            if (customEnd != null &&
                d.isAfter(customEnd!.add(const Duration(days: 1)))) return false;
            break;
          case _DateRange.all:
            break;
        }
      }
      if (storeId != null && o.storeId != storeId) return false;
      if (serviceName != null && o.serviceName != serviceName) return false;

      if (status != null && OrderStatus.getDisplayStatus(o.status) != status) {
        return false;
      }

      return true;
    }).toList();

    switch (sortBy) {
      case 'oldest':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_asc':
        result.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case 'price_desc':
        result.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      default: // newest
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }
}

const _sentinel = Object();

// ─── Main Screen ──────────────────────────────────────────────────────────────

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  _OrderFilter _filter = const _OrderFilter();

  void _showFilterSheet(BuildContext ctx, List<OrderEntity> allOrders) async {
    final result = await showModalBottomSheet<_OrderFilter>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: _filter,
        allOrders: allOrders,
      ),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: GradientAppBar(
        title: 'My Orders',
        backEnabled: false,
        trailing: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (ctx, state) {
            if (state is! OrdersLoaded) return const SizedBox.shrink();
            final allOrders = state.orders;
            return GestureDetector(
              onTap: () => _showFilterSheet(ctx, allOrders),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.filter_list_outlined,
                        color: Colors.white, size: 20),
                  ),
                  if (_filter.activeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_filter.activeCount}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (_, s) => s is OrderCancelled || s is OrdersError,
        buildWhen: (prev, current) =>
        current is OrdersInitial ||
            current is OrdersLoading ||
            current is OrdersLoaded ||
            current is OrdersError,
        listener: (context, state) {
          if (state is OrderCancelled) {
            AppSnackBar.show(context, 'Order cancelled.', isError: false);
          } else if (state is OrdersError) {
            AppSnackBar.show(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is OrdersInitial || state is OrdersLoading) {
            return _OrdersShimmer(isDark: isDark);
          }

          if (state is OrdersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 52),
                  const SizedBox(height: 14),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alexandria(
                        fontSize: 14,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () =>
                        context.read<OrdersBloc>().add(const OrdersLoadRequested()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text('Retry',
                        style: GoogleFonts.alexandria(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            );
          }
          if (state is OrdersLoaded) {
            return _OrdersBody(
              state: state,
              isDark: isDark,
              filter: _filter,
              onClearFilter: () => setState(() => _filter = const _OrderFilter()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradient,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(RoutesName.placeOrdersNavigate),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─── Shimmer Loader ───────────────────────────────────────────────────────────

class _OrdersShimmer extends StatelessWidget {
  final bool isDark;
  const _OrdersShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        16,
        Responsive.horizontalPadding(context),
        10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, __) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Orders list view ─────────────────────────────────────────────────────────

class _OrdersBody extends StatefulWidget {
  final OrdersLoaded state;
  final bool isDark;
  final _OrderFilter filter;
  final VoidCallback onClearFilter;

  const _OrdersBody({
    required this.state,
    required this.isDark,
    required this.filter,
    required this.onClearFilter,
  });

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  late PageController _pageController;
  late bool _showActive;

  @override
  void initState() {
    super.initState();
    _showActive = widget.state.showActive;
    _pageController = PageController(initialPage: _showActive ? 0 : 1);
  }

  @override
  void didUpdateWidget(covariant _OrdersBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.showActive != widget.state.showActive) {
      if (_showActive != widget.state.showActive) {
        _showActive = widget.state.showActive;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _showActive ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildList(List<OrderEntity> displayed, bool isActiveTab) {
    if (displayed.isEmpty) {
      return _OrderEmptyState(
        showActive: isActiveTab,
        isDark: widget.isDark,
        isFiltered: widget.filter.isActive,
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final order = displayed[i];
        final tab = isActiveTab ? 'a' : 'h';
        return _OrderCard(
          key: ValueKey('${tab}_${order.id}'),
          order: order,
          isHistory: !isActiveTab,
          isDark: widget.isDark,
          onPress: () => context.push(RoutesName.trackOrdersNavigate, extra: order.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.state.orders.where((o) => o.isActive).toList();
    final historyOrders = widget.state.orders.where((o) => !o.isActive).toList();

    final activeDisplayed = widget.filter.apply(activeOrders);
    final historyDisplayed = widget.filter.apply(historyOrders);

    final currentDisplayed = _showActive ? activeDisplayed : historyDisplayed;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        16,
        Responsive.horizontalPadding(context),
        5,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Column(children: [
            _OrdersToggle(
              showActive: _showActive,
              isDark: widget.isDark,
              pageController: _pageController,
              onChanged: (active) {
                setState(() => _showActive = active);
                _pageController.animateToPage(
                  active ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                context.read<OrdersBloc>().add(OrdersFilterToggled(active));
              },
            ),
            if (widget.filter.isActive) ...[
              const SizedBox(height: 10),
              _ActiveFilterBar(
                  filter: widget.filter,
                  isDark: widget.isDark,
                  onClear: widget.onClearFilter,
                  allOrders: widget.state.orders),
            ],
            const SizedBox(height: 12),
            if (widget.filter.isActive)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${currentDisplayed.length} result${currentDisplayed.length == 1 ? '' : 's'}',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  final isActive = idx == 0;
                  if (isActive != _showActive) {
                    setState(() => _showActive = isActive);
                  }
                  if (isActive != widget.state.showActive) {
                    context.read<OrdersBloc>().add(OrdersFilterToggled(isActive));
                  }
                },
                children: [
                  _buildList(activeDisplayed, true),
                  _buildList(historyDisplayed, false),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Active filter bar ────────────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  final _OrderFilter filter;
  final bool isDark;
  final VoidCallback onClear;
  final List<OrderEntity> allOrders;

  const _ActiveFilterBar({
    required this.filter,
    required this.isDark,
    required this.onClear,
    required this.allOrders,
  });

  String _dateLabel(_DateRange r) {
    switch (r) {
      case _DateRange.today:
        return 'Today';
      case _DateRange.last7:
        return 'Last 7 days';
      case _DateRange.last30:
        return 'Last 30 days';
      case _DateRange.custom:
        return 'Custom date';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.dateRange != _DateRange.all) chips.add(_dateLabel(filter.dateRange));

    if (filter.storeId != null) {
      final storeIndex = allOrders.indexWhere((o) => o.storeId == filter.storeId);
      final displayName = storeIndex != -1 ? allOrders[storeIndex].storeName : filter.storeId!;
      chips.add(displayName);
    }

    if (filter.serviceName != null) chips.add(filter.serviceName!);
    if (filter.status != null) chips.add(OrderStatus.format(filter.status!));

    if (filter.sortBy != 'newest') {
      chips.add({
        'oldest': 'Oldest first',
        'price_asc': 'Price ↑',
        'price_desc': 'Price ↓',
      }[filter.sortBy] ??
          filter.sortBy ??
          '');
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...chips.map((c) => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              c,
              style: GoogleFonts.alexandria(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.close_rounded, size: 12, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  'Clear all',
                  style: GoogleFonts.alexandria(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet (Draggable) ──────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _OrderFilter current;
  final List<OrderEntity> allOrders;

  const _FilterSheet({required this.current, required this.allOrders});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _OrderFilter _f;

  late final List<String> _storeNames;
  late final List<String> _serviceNames;
  late final List<String> _availableStatuses;

  static const _sortOptions = {
    'newest': 'Newest first',
    'oldest': 'Oldest first',
    'price_asc': 'Price: Low → High',
    'price_desc': 'Price: High → Low',
  };

  late final Map<String, String> _storeMap;

  @override
  void initState() {
    super.initState();
    _f = widget.current;
    _storeMap = {for (final o in widget.allOrders) o.storeId: o.storeName};
    _storeNames = _storeMap.values.toSet().toList()..sort();
    _serviceNames = widget.allOrders.map((o) => o.serviceName).toSet().toList()..sort();

    _availableStatuses =
    widget.allOrders.map((o) => OrderStatus.getDisplayStatus(o.status)).toSet().toList()..sort();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => isDark ? AppColors.darkSurface : Colors.white;
  Color get _textColor => isDark ? Colors.white : AppColors.lightText;

  Widget _sectionTitle(String t, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(t,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textColor,
            )),
      ],
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradient : null,
          color: selected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade300)),
        ),
        child: Text(label,
            style: GoogleFonts.alexandria(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            )),
      ),
    );
  }

  Future<void> _pickCustomDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _f.customStart : _f.customEnd) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _f = isStart
          ? _f.copyWith(dateRange: _DateRange.custom, customStart: picked)
          : _f.copyWith(dateRange: _DateRange.custom, customEnd: picked);
    });
  }

  String _fmtDate(DateTime? d) => d == null
      ? 'Select'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  children: [
                    Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                    const SizedBox(height: 16),
                    Row(children: [
                      Text('Filter Orders',
                          style: GoogleFonts.alexandria(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          )),
                      const Spacer(),
                      if (_f.isActive)
                        GestureDetector(
                          onTap: () => setState(() => _f = const _OrderFilter()),
                          child: Text('Reset',
                              style: GoogleFonts.alexandria(
                                fontSize: 13,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                    ]),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Date Range', Iconsax.calendar),
                      Wrap(children: [
                        _chip(
                            label: 'All time',
                            selected: _f.dateRange == _DateRange.all,
                            onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.all))),
                        _chip(
                            label: 'Today',
                            selected: _f.dateRange == _DateRange.today,
                            onTap: () =>
                                setState(() => _f = _f.copyWith(dateRange: _DateRange.today))),
                        _chip(
                            label: 'Last 7 days',
                            selected: _f.dateRange == _DateRange.last7,
                            onTap: () =>
                                setState(() => _f = _f.copyWith(dateRange: _DateRange.last7))),
                        _chip(
                            label: 'Last 30 days',
                            selected: _f.dateRange == _DateRange.last30,
                            onTap: () =>
                                setState(() => _f = _f.copyWith(dateRange: _DateRange.last30))),
                        _chip(
                            label: 'Custom',
                            selected: _f.dateRange == _DateRange.custom,
                            onTap: () =>
                                setState(() => _f = _f.copyWith(dateRange: _DateRange.custom))),
                      ]),
                      if (_f.dateRange == _DateRange.custom) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _ThemedDateButton(
                                  label: 'From',
                                  value: _fmtDate(_f.customStart),
                                  onTap: () => _pickCustomDate(true),
                                  isDark: isDark)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _ThemedDateButton(
                                  label: 'To',
                                  value: _fmtDate(_f.customEnd),
                                  onTap: () => _pickCustomDate(false),
                                  isDark: isDark)),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      if (_storeNames.isNotEmpty) ...[
                        _sectionTitle('Store Location', Iconsax.shop),
                        Wrap(children: [
                          _chip(
                              label: 'All stores',
                              selected: _f.storeId == null,
                              onTap: () => setState(() => _f = _f.copyWith(storeId: null))),
                          ..._storeMap.entries.map((e) => _chip(
                            label: e.value,
                            selected: _f.storeId == e.key,
                            onTap: () => setState(() => _f = _f.copyWith(storeId: e.key)),
                          )),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      if (_serviceNames.isNotEmpty) ...[
                        _sectionTitle('Service Category', Iconsax.category),
                        Wrap(children: [
                          _chip(
                              label: 'All services',
                              selected: _f.serviceName == null,
                              onTap: () => setState(() => _f = _f.copyWith(serviceName: null))),
                          ..._serviceNames.map((s) => _chip(
                            label: s,
                            selected: _f.serviceName == s,
                            onTap: () => setState(() => _f = _f.copyWith(serviceName: s)),
                          )),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      if (_availableStatuses.isNotEmpty) ...[
                        _sectionTitle('Order Status', Iconsax.status),
                        Wrap(children: [
                          _chip(
                              label: 'All statuses',
                              selected: _f.status == null,
                              onTap: () => setState(() => _f = _f.copyWith(status: null))),
                          ..._availableStatuses.map((s) {
                            final color = OrderStatus.getColor(s);
                            return _chip(
                              label: OrderStatus.format(s),
                              selected: _f.status == s,
                              color: color,
                              onTap: () => setState(() => _f = _f.copyWith(status: s)),
                            );
                          }),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      _sectionTitle('Sort Results', Iconsax.sort),
                      Wrap(
                          children: _sortOptions.entries
                              .map((e) => _chip(
                            label: e.value,
                            selected: _f.sortBy == e.key,
                            onTap: () => setState(() => _f = _f.copyWith(sortBy: e.key)),
                          ))
                              .toList()),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => Navigator.pop(context, _f),
                            child: Text('Apply Filters',
                                style: GoogleFonts.alexandria(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemedDateButton extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemedDateButton(
      {required this.label, required this.value, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.alexandria(
                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(value,
                  style: GoogleFonts.alexandria(
                      fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
              const Icon(Iconsax.calendar_1, size: 14, color: AppColors.primary),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _OrderEmptyState extends StatelessWidget {
  final bool showActive, isDark, isFiltered;
  const _OrderEmptyState({required this.showActive, required this.isDark, required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          isFiltered ? Iconsax.search_normal : (showActive ? Iconsax.truck_fast : Iconsax.box),
          size: 72,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        const SizedBox(height: 16),
        Text(
          isFiltered
              ? 'No orders match your filters'
              : (showActive ? 'No active orders' : 'No completed orders'),
          style: GoogleFonts.alexandria(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isFiltered
              ? 'Try adjusting or clearing your filters'
              : (showActive
              ? 'Tap + to book your first laundry service'
              : 'Completed orders will appear here'),
          style: GoogleFonts.alexandria(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

// ─── Tab toggle (Animated Slide) ──────────────────────────────────────────────

class _OrdersToggle extends StatelessWidget {
  final bool showActive;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  final PageController pageController;

  const _OrdersToggle({
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double page = showActive ? 0.0 : 1.0;

              if (pageController.hasClients && pageController.position.haveDimensions) {
                page = pageController.page ?? page;
              }

              page = page.clamp(0.0, 1.0);
              final alignmentX = (page * 2) - 1.0;

              return Align(
                alignment: Alignment(alignmentX, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: showActive
                            ? Colors.white
                            : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
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
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: !showActive
                            ? Colors.white
                            : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
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

// ─── Individual Order Card ────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final OrderEntity order;
  final bool isHistory, isDark;
  final VoidCallback onPress;
  const _OrderCard(
      {super.key, required this.order, required this.isHistory, required this.isDark, required this.onPress});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  void _confirmCancel(BuildContext ctx) {
    showDialog(
        context: ctx,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Cancel Order?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
          content: Text('Cancel order #${widget.order.orderNumber}? This cannot be undone.',
              style: GoogleFonts.alexandria(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text('Keep Order',
                    style: GoogleFonts.alexandria(
                        color: AppColors.primary, fontWeight: FontWeight.w600))),
            TextButton(
                onPressed: () {
                  Navigator.pop(dCtx);
                  ctx.read<OrdersBloc>().add(OrderCancelRequested(widget.order.id));
                },
                child: Text('Yes, Cancel',
                    style: GoogleFonts.alexandria(
                        color: AppColors.error, fontWeight: FontWeight.w600))),
          ],
        ));
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderReviewSheet(order: widget.order, isDark: widget.isDark),
    );
  }

  Future<void> _handleReorder(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReorderSheet(order: widget.order, isDark: widget.isDark));
    if (result == null || !context.mounted) return;
    context.push(RoutesName.placeOrdersNavigate,
        extra: ReorderParams(
          serviceId: widget.order.serviceId,
          storeId: widget.order.storeId,
          serviceName: widget.order.serviceName,
          storeName: widget.order.storeName,
          itemCount: widget.order.itemCount,
          totalPrice: widget.order.totalPrice,
          pickupAddress: widget.order.pickupAddress,
          deliveryAddress: widget.order.deliveryAddress,
          specialInstructions: widget.order.specialInstructions,
          pickupDate: result['pickupDate'] as DateTime,
          pickupTime: result['pickupTime'] as String,
          deliveryDate: result['deliveryDate'] as DateTime,
          deliveryTime: result['deliveryTime'] as String,
          paymentMethod: widget.order.paymentMethod,
        ));
  }

  // UPDATED: Flowing Timeline Builder starting from Confirmed (threshold 2)
  Widget _buildFlowingTimeline(int currentLevel, bool isDark) {
    final steps = [
      {'threshold': 2, 'title': 'Confirmed', 'sub': 'Store has accepted your order.'},
      {'threshold': 4, 'title': 'Picked Up', 'sub': 'Items picked up and heading to laundry.'},
      {'threshold': 7, 'title': 'Cleaning', 'sub': 'Washing, drying, and ironing.'},
      {'threshold': 9, 'title': 'Out for Delivery', 'sub': 'Rider is on the way to deliver.'},
      {'threshold': 10, 'title': 'Delivered', 'sub': 'Order completed successfully.'},
    ];

    return Column(
      children: steps.asMap().entries.map((e) {
        final index = e.key;
        final step = e.value;
        final threshold = step['threshold'] as int;

        final isDone = currentLevel >= threshold;
        // Active if not done, and this is either the first step or the previous step was done
        final isActive = !isDone && (index == 0 || currentLevel >= (steps[index - 1]['threshold'] as int));
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
                    border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 4) : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : (isActive
                      ? Center(
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary)))
                      : null),
                ),
                if (!isLast)
                // UPDATED: Line segment height is fixed to prevent expansion during status updates
                  SizedBox(
                    height: 44,
                    width: 2,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(width: 2, color: isDark ? Colors.white12 : Colors.grey.shade200),
                        // FLOWING PROGRESS BAR ANIMATION
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          width: 2,
                          height: isDone ? 44.0 : 0.0,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step['title'] as String,
                        style: GoogleFonts.alexandria(
                            fontWeight: isDone || isActive ? FontWeight.bold : FontWeight.w500,
                            color: isDone || isActive ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade500,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(step['sub'] as String,
                        style: GoogleFonts.alexandria(
                            fontSize: 12, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;

    final displayStatus = OrderStatus.getDisplayStatus(o.status);
    final statusColor = OrderStatus.getColor(displayStatus);
    final currentLevel = OrderStatus.getStepCompletionOrder(displayStatus);
    final progress = o.progress.clamp(0.0, 1.0);

    final canCancel = currentLevel < OrderStatus.getStepCompletionOrder(OrderStatus.assignPickup);

    return GestureDetector(
      onTap: widget.onPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: widget.isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _ServiceImage(imageUrl: o.serviceImageUrl, isDark: widget.isDark),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.serviceName,
                      style: GoogleFonts.alexandria(
                          fontWeight: FontWeight.bold, fontSize: 15, color: widget.isDark ? Colors.white : AppColors.lightText)),
                  const SizedBox(height: 3),
                  Text(o.storeName,
                      style: GoogleFonts.alexandria(
                          fontSize: 12, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  const SizedBox(height: 5),
                  Row(children: [
                    Text('#${o.orderNumber}',
                        style: GoogleFonts.alexandria(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(OrderStatus.format(displayStatus).toUpperCase(),
                          style: GoogleFonts.alexandria(
                              fontSize: 9, color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ]),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('৳${o.totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('${o.itemCount} pcs',
                  style: GoogleFonts.alexandria(
                      fontSize: 11, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            ]),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 6,
                color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
                child: LayoutBuilder(
                    builder: (_, c) => Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: c.maxWidth * progress,
                        decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(10)),
                      ),
                    )),
              )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: widget.isHistory
                  ? OutlinedButton.icon(
                icon: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 18),
                onPressed: () => _showReviewSheet(context),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                label: Text('Review',
                    style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              )
                  : OutlinedButton.icon(
                icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.remove_red_eye_outlined,
                    color: AppColors.primary, size: 18),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                label: Text(_expanded ? 'Hide' : 'Details',
                    style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: widget.isHistory
                  ? Container(
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12), boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.replay_outlined, color: Colors.white, size: 16),
                  onPressed: () => _handleReorder(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  label: Text('Reorder',
                      style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              )
                  : BlocBuilder<OrdersBloc, OrdersState>(builder: (ctx, bState) {
                final cancelling = bState is OrderCancelling;
                final isButtonDisabled = cancelling || !canCancel;

                final bgColor = isButtonDisabled ? (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200) : AppColors.error;
                final textColor =
                isButtonDisabled ? (widget.isDark ? Colors.grey.shade500 : Colors.grey.shade500) : Colors.white;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isButtonDisabled
                      ? () {
                    if (!canCancel && !cancelling) {
                      AppSnackBar.show(context, 'Order cannot be cancelled after a rider is assigned.',
                          isError: true);
                    }
                  }
                      : () => _confirmCancel(ctx),
                  child: Container(
                    decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isButtonDisabled
                            ? []
                            : [BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: cancelling
                          ? const SizedBox(
                          width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Icon(Icons.cancel_outlined, color: textColor, size: 16),
                      label: Text(cancelling ? 'Cancelling…' : 'Cancel',
                          style: GoogleFonts.alexandria(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                );
              }),
            ),
          ]),
          // UPDATED: Expands showing the Flowing Tracking Timeline (Address details and AnimatedSize removed)
          if (_expanded && !widget.isHistory) ...[
            const SizedBox(height: 24),
            Divider(color: widget.isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 20),
            Text('Order Tracking',
                style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold, fontSize: 15, color: widget.isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 24),
            if (displayStatus == OrderStatus.cancelled)
              Row(children: [
                const Icon(Icons.cancel_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text('This order was cancelled.',
                    style: GoogleFonts.alexandria(color: AppColors.error, fontWeight: FontWeight.w600))
              ])
            else
              _buildFlowingTimeline(currentLevel, widget.isDark),
          ],
        ]),
      ),
    );
  }
}

// ─── Support classes ──────────────────────────────────────────────────────────

class _OrderReviewSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;

  const _OrderReviewSheet({required this.order, required this.isDark});

  @override
  State<_OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<_OrderReviewSheet> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  final _ctrl = TextEditingController();

  double _rating = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _ctrl.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Please write a comment.');
      return;
    }
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _error = 'You must be signed in to review.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _client.from(AppConstants.reviewsTable).insert({
        'service_id': widget.order.serviceId,
        'user_id': uid,
        'rating': _rating,
        'comment': comment,
      });

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(context, 'Review submitted successfully!', isError: false);
      }
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString().contains('duplicate') || e.toString().contains('unique')
            ? 'You have already reviewed this service.'
            : 'Failed to submit. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bg = widget.isDark ? AppColors.darkSurface : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetHandle(isDark: widget.isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Write a Review',
                        style: GoogleFonts.alexandria(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: widget.isDark ? Colors.white : AppColors.lightText)),
                    Text(widget.order.serviceName,
                        style: GoogleFonts.alexandria(
                            fontSize: 12, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                  ]),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: widget.isDark ? Colors.white54 : Colors.black38),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(height: 1, color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final on = i < _rating;
                          return GestureDetector(
                            onTap: () => setState(() => _rating = (i + 1).toDouble()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  on ? Icons.star_rounded : Icons.star_outline_rounded,
                                  key: ValueKey('$i-$on'),
                                  color: on ? const Color(0xFFFBBF24) : (widget.isDark ? Colors.white24 : Colors.black26),
                                  size: 40,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _label(_rating),
                          key: ValueKey(_rating),
                          style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: _labelColor(_rating)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    maxLength: 500,
                    style: GoogleFonts.alexandria(fontSize: 14, color: widget.isDark ? Colors.white : AppColors.lightText),
                    decoration: InputDecoration(
                      hintText: 'Share your experience…',
                      hintStyle: GoogleFonts.alexandria(color: widget.isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                      filled: true,
                      fillColor: widget.isDark ? AppColors.darkBackground : const Color(0xFFF8FAFF),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      counterStyle:
                      GoogleFonts.alexandria(fontSize: 11, color: widget.isDark ? Colors.white30 : Colors.black38),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: GoogleFonts.alexandria(color: AppColors.error, fontSize: 12))),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _submitting ? null : AppColors.gradient,
                        color: _submitting ? AppColors.primary.withOpacity(0.5) : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _submitting
                            ? []
                            : [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Submit Review',
                            style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  String _label(double r) {
    if (r >= 5) return 'Excellent ✨';
    if (r >= 4) return 'Very Good 👍';
    if (r >= 3) return 'Good 😊';
    if (r >= 2) return 'Fair 😐';
    return 'Poor 😞';
  }

  Color _labelColor(double r) {
    if (r >= 4) return AppColors.success;
    if (r >= 3) return AppColors.warning;
    return AppColors.error;
  }
}

class _ReorderSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;

  const _ReorderSheet({super.key, required this.order, required this.isDark});

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late DateTime _pickupDate;
  late String _pickupTime;
  late DateTime _deliveryDate;
  late String _deliveryTime;

  List<String> _pickupTimeSlots = [];
  List<String> _deliveryTimeSlots = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pickupDate = BusinessLogicUtils.getMinPickupDate();
    _pickupTime = 'Select time';
    _deliveryDate = _pickupDate;
    _deliveryTime = 'Select time';

    _refreshPickupLogic();
  }

  Future<void> _refreshPickupLogic() async {
    setState(() => _isChecking = true);

    List<String> slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
      widget.order.storeId,
      _pickupDate,
      isPickup: true,
      categories: [widget.order.serviceName],
    );

    while (slots.isEmpty) {
      _pickupDate = BusinessLogicUtils.getNextBusinessDay(_pickupDate);
      slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
        widget.order.storeId,
        _pickupDate,
        isPickup: true,
        categories: [widget.order.serviceName],
      );
    }

    setState(() {
      _pickupTimeSlots = slots;
      _pickupTime = _pickupTimeSlots.isNotEmpty ? _pickupTimeSlots.first : 'Select time';
      _isChecking = false;
    });

    await _syncDeliveryLogic();
  }

  Future<void> _syncDeliveryLogic() async {
    if (_pickupTime == 'Select time') return;

    final minRequired = BusinessLogicUtils.getMinDeliveryDate(
      _pickupDate,
      _pickupTime,
      widget.order.serviceName,
      totalItems: widget.order.itemCount,
    );

    if (_deliveryDate.isBefore(minRequired)) {
      _deliveryDate = minRequired;
    }

    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      widget.order.storeId,
      _deliveryDate,
      pickupDate: _pickupDate,
      pickupTime: _pickupTime,
      serviceName: widget.order.serviceName,
      totalItems: widget.order.itemCount,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        widget.order.storeId,
        _deliveryDate,
        pickupDate: _pickupDate,
        pickupTime: _pickupTime,
        serviceName: widget.order.serviceName,
        totalItems: widget.order.itemCount,
      );
    }

    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty ? _deliveryTimeSlots.first : 'Select time';
    });
  }

  Future<void> _handleConfirm() async {
    if (_pickupTime == 'Select time' || _deliveryTime == 'Select time') {
      AppSnackBar.show(context, 'Please select both dates and times', isError: true);
      return;
    }

    if (!BusinessLogicUtils.isSubmissionStillValid(_pickupDate, _pickupTime)) {
      AppSnackBar.show(
        context,
        'Selected pickup time is within the 2-hour no-change window. Please choose a later slot.',
        isError: true,
      );
      return;
    }

    setState(() => _isChecking = true);

    final isAvailable = await BusinessLogicUtils.isSlotAvailable(
      widget.order.storeId,
      _pickupDate,
      _pickupTime,
      orderValue: widget.order.totalPrice,
      orderItemCount: widget.order.itemCount,
    );

    setState(() => _isChecking = false);

    if (!isAvailable) {
      AppSnackBar.show(
        context,
        'This slot has reached capacity. Please pick another time.',
        isError: true,
      );
      return;
    }

    Navigator.pop(context, {
      'pickupDate': _pickupDate,
      'pickupTime': _pickupTime,
      'deliveryDate': _deliveryDate,
      'deliveryTime': _deliveryTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = _pickupTime != 'Select time' && _deliveryTime != 'Select time' && !_isChecking;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: AppSheetHandle(isDark: widget.isDark)),
          const SizedBox(height: 20),
          Text(
            'Reschedule Reorder',
            style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your preferred pickup and delivery slots.',
            style: GoogleFonts.alexandria(
                fontSize: 13, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
          const SizedBox(height: 24),

          // ─── Pickup Section ───
          _buildSectionTitle('Pickup Schedule'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  label: 'Pickup Date',
                  date: _pickupDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _pickupDate,
                      firstDate: BusinessLogicUtils.getMinPickupDate(),
                      lastDate: BusinessLogicUtils.getMaxPickupDate(),
                      selectableDayPredicate: (DateTime val) =>
                      !BusinessLogicUtils.isClosedDay(val) &&
                          BusinessLogicUtils.getAvailableSlots(
                            val,
                            isPickup: true,
                            categories: [widget.order.serviceName],
                          ).isNotEmpty,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _pickupDate = BusinessLogicUtils.clampToMinPickupDate(picked));
                      await _refreshPickupLogic();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDropdown(
                  value: _pickupTime,
                  items: _pickupTimeSlots,
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _pickupTime = val);
                      await _syncDeliveryLogic();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── Delivery Section ───
          _buildSectionTitle('Delivery Schedule'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  label: 'Delivery Date',
                  date: _deliveryDate,
                  onTap: () async {
                    final minDate = BusinessLogicUtils.getMinDeliveryDate(
                      _pickupDate,
                      _pickupTime,
                      widget.order.serviceName,
                    );
                    final maxDate = BusinessLogicUtils.getMaxPickupDate()
                        .add(Duration(days: BusinessLogicUtils.kStandardHours ~/ 8 + 2));
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deliveryDate,
                      firstDate: minDate,
                      lastDate: maxDate,
                      selectableDayPredicate: (DateTime val) =>
                      !BusinessLogicUtils.isClosedDay(val) &&
                          BusinessLogicUtils.getDeliverySlots(
                            val,
                            pickupDate: _pickupDate,
                            pickupTime: _pickupTime,
                            serviceName: widget.order.serviceName,
                          ).isNotEmpty,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _deliveryDate = picked;
                        while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
                          _deliveryDate = _deliveryDate.add(const Duration(days: 1));
                        }
                      });
                      await _syncDeliveryLogic();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeDropdown(
                  value: _deliveryTime,
                  items: _deliveryTimeSlots,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _deliveryTime = val);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ─── Confirm Button ───
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: canProceed ? AppColors.gradient : null,
                color: canProceed ? null : (widget.isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: canProceed ? _handleConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isChecking
                    ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                  'Confirm & Place Order',
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    color: canProceed ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI Helpers ───

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.alexandria(
          fontSize: 13, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white70 : Colors.black87),
    );
  }

  Widget _buildDateTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkBackground : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.isDark ? AppColors.darkBorder : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(date), style: GoogleFonts.alexandria(fontSize: 13)),
            Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      hint: Text('Time', style: GoogleFonts.alexandria(fontSize: 13)),
      items: items
          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.alexandria(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: widget.isDark ? AppColors.darkBackground : Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: widget.isDark ? AppColors.darkBorder : Colors.grey.shade300)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  const _ServiceImage({this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        gradient: imageUrl == null ? AppColors.gradient : null,
        color: imageUrl != null ? (isDark ? AppColors.darkSurface : Colors.grey.shade100) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(color: Colors.white)),
          errorWidget: (_, __, ___) => Container(
              decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 28)),
        )
            : const Icon(Icons.local_laundry_service, color: Colors.white, size: 28),
      ),
    );
  }
}
class ReorderParams {
  final String serviceId, storeId, serviceName, storeName;
  final int itemCount;
  final double totalPrice;
  final String pickupAddress;
  final String? deliveryAddress, specialInstructions;
  final DateTime pickupDate, deliveryDate;
  final String pickupTime, deliveryTime, paymentMethod;

  const ReorderParams({
    required this.serviceId, required this.storeId, required this.serviceName,
    required this.storeName, required this.itemCount, required this.totalPrice,
    required this.pickupAddress, this.deliveryAddress, this.specialInstructions,
    required this.pickupDate, required this.pickupTime, required this.deliveryDate,
    required this.deliveryTime, required this.paymentMethod,
  });
}