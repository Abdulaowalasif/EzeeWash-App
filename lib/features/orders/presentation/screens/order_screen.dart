// lib/features/orders/presentation/screens/order_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';

// ─── Filter model (pure local, no bloc changes needed) ───────────────────────

enum _DateRange { all, today, last7, last30, custom }

class _OrderFilter {
  final _DateRange dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? storeId;     // null = all
  final String? serviceName; // null = all
  final String? status;      // null = all
  final String? sortBy;      // 'newest' | 'oldest' | 'price_asc' | 'price_desc'

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
  }) =>
      _OrderFilter(
        dateRange: dateRange ?? this.dateRange,
        customStart: customStart ?? this.customStart,
        customEnd: customEnd ?? this.customEnd,
        storeId: storeId == _sentinel ? this.storeId : storeId as String?,
        serviceName: serviceName == _sentinel ? this.serviceName : serviceName as String?,
        status: status == _sentinel ? this.status : status as String?,
        sortBy: sortBy ?? this.sortBy,
      );

  List<OrderEntity> apply(List<OrderEntity> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var result = orders.where((o) {
      // ── date range ──
      if (dateRange != _DateRange.all) {
        final d = o.createdAt;
        switch (dateRange) {
          case _DateRange.today:
            if (d.isBefore(today)) return false;
          case _DateRange.last7:
            if (d.isBefore(today.subtract(const Duration(days: 7)))) return false;
          case _DateRange.last30:
            if (d.isBefore(today.subtract(const Duration(days: 30)))) return false;
          case _DateRange.custom:
            if (customStart != null && d.isBefore(customStart!)) return false;
            if (customEnd != null && d.isAfter(customEnd!.add(const Duration(days: 1)))) return false;
          case _DateRange.all:
            break;
        }
      }
      // ── store ──
      if (storeId != null && o.storeId != storeId) return false;
      // ── category/service ──
      if (serviceName != null && o.serviceName != serviceName) return false;
      // ── status ──
      if (status != null && o.status != status) return false;
      return true;
    }).toList();

    // ── sort ──
    switch (sortBy) {
      case 'oldest':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'price_asc':
        result.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
      case 'price_desc':
        result.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
      default: // newest
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }
}

const _sentinel = Object();

// ─── Screen ───────────────────────────────────────────────────────────────────

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 10,
              Responsive.horizontalPadding(context), 10,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('My Orders',
                  style: GoogleFonts.alexandria(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (ctx, state) {
                    if (state is! OrdersLoaded) return const SizedBox.shrink();
                    final allOrders = state.orders;
                    return GestureDetector(
                      onTap: () => _showFilterSheet(ctx, allOrders),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.filter, color: Colors.white, size: 20),
                          ),
                          if (_filter.activeCount > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                width: 16, height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${_filter.activeCount}',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (_, s) => s is OrderCancelled || s is OrdersError,
        listener: (context, state) {
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Order cancelled.', style: GoogleFonts.alexandria(fontSize: 13)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          } else if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: GoogleFonts.alexandria(fontSize: 13)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          }
        },
        builder: (context, state) {
          if (state is OrdersInitial || state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 52),
                  const SizedBox(height: 14),
                  Text(state.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alexandria(fontSize: 14,
                        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () => context.read<OrdersBloc>().add(const OrdersLoadRequested()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text('Retry', style: GoogleFonts.alexandria(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            );
          }
          if (state is OrdersLoaded) {
            return _OrdersBody(state: state, isDark: isDark, filter: _filter,
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
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
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

// ─── Orders body ──────────────────────────────────────────────────────────────

class _OrdersBody extends StatelessWidget {
  final OrdersLoaded state;
  final bool isDark;
  final _OrderFilter filter;
  final VoidCallback onClearFilter;

  const _OrdersBody({
    required this.state, required this.isDark,
    required this.filter, required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final activeOrders = state.orders.where((o) => o.isActive).toList();
    final historyOrders = state.orders.where((o) => !o.isActive).toList();
    final base = state.showActive ? activeOrders : historyOrders;
    final displayed = filter.apply(base);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context), vertical: 10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Column(children: [
            _OrdersToggle(
              showActive: state.showActive, isDark: isDark,
              onChanged: (active) => context.read<OrdersBloc>().add(OrdersFilterToggled(active)),
            ),
            // Active filter chips
            if (filter.isActive) ...[
              const SizedBox(height: 10),
              _ActiveFilterBar(filter: filter, isDark: isDark, onClear: onClearFilter),
            ],
            const SizedBox(height: 12),
            // Results count
            if (filter.isActive)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${displayed.length} result${displayed.length == 1 ? '' : 's'}',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: displayed.isEmpty
                  ? _EmptyState(showActive: state.showActive, isDark: isDark, isFiltered: filter.isActive)
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final order = displayed[i];
                  final tab = state.showActive ? 'a' : 'h';
                  return _OrderCard(
                    key: ValueKey('${tab}_${order.id}_${order.status}'),
                    order: order,
                    isHistory: !state.showActive,
                    isDark: isDark,
                    onPress: () => context.push(RoutesName.trackOrdersNavigate, extra: order.id),
                  );
                },
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

  const _ActiveFilterBar({required this.filter, required this.isDark, required this.onClear});

  String _dateLabel(_DateRange r) {
    switch (r) {
      case _DateRange.today: return 'Today';
      case _DateRange.last7: return 'Last 7 days';
      case _DateRange.last30: return 'Last 30 days';
      case _DateRange.custom: return 'Custom date';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.dateRange != _DateRange.all) chips.add(_dateLabel(filter.dateRange));
    if (filter.storeId != null) chips.add(filter.storeId!);
    if (filter.serviceName != null) chips.add(filter.serviceName!);
    if (filter.status != null) chips.add(filter.status!.replaceAll('_', ' '));
    if (filter.sortBy != 'newest') {
      chips.add({
        'oldest': 'Oldest first',
        'price_asc': 'Price ↑',
        'price_desc': 'Price ↓',
      }[filter.sortBy] ?? filter.sortBy!);
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
            child: Text(c,
              style: GoogleFonts.alexandria(
                fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600,
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
                Text('Clear all',
                  style: GoogleFonts.alexandria(
                    fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600,
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

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _OrderFilter current;
  final List<OrderEntity> allOrders;

  const _FilterSheet({required this.current, required this.allOrders});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _OrderFilter _f;

  // Derived unique values from loaded orders
  late final List<String> _storeNames;
  late final List<String> _serviceNames;
  static const _statuses = [
    'pending', 'confirmed', 'picked_up', 'in_process',
    'ready', 'out_for_delivery', 'delivered', 'cancelled',
  ];
  static const _sortOptions = {
    'newest': 'Newest first',
    'oldest': 'Oldest first',
    'price_asc': 'Price: Low → High',
    'price_desc': 'Price: High → Low',
  };

  // Map storeId → storeName (for display)
  late final Map<String, String> _storeMap;

  @override
  void initState() {
    super.initState();
    _f = widget.current;
    _storeMap = { for (final o in widget.allOrders) o.storeId: o.storeName };
    _storeNames = _storeMap.values.toSet().toList()..sort();
    _serviceNames = widget.allOrders.map((o) => o.serviceName).toSet().toList()..sort();
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => isDark ? AppColors.darkSurface : Colors.white;
  Color get _textColor => isDark ? Colors.white : AppColors.lightText;
  Color get _subColor => isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.alexandria(
      fontSize: 13, fontWeight: FontWeight.bold, color: _textColor,
    )),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : c.withOpacity(0.25)),
        ),
        child: Text(label, style: GoogleFonts.alexandria(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? Colors.white : c,
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
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          // Header
          Row(children: [
            Text('Filter Orders', style: GoogleFonts.alexandria(
              fontSize: 20, fontWeight: FontWeight.bold, color: _textColor,
            )),
            const Spacer(),
            if (_f.isActive)
              GestureDetector(
                onTap: () => setState(() => _f = const _OrderFilter()),
                child: Text('Reset', style: GoogleFonts.alexandria(
                  fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600,
                )),
              ),
          ]),
          const SizedBox(height: 24),

          // ── Date Range ──────────────────────────────────────────────────
          _sectionTitle('Date Range'),
          Wrap(children: [
            _chip(label: 'All time',   selected: _f.dateRange == _DateRange.all,    onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.all))),
            _chip(label: 'Today',      selected: _f.dateRange == _DateRange.today,  onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.today))),
            _chip(label: 'Last 7 days',selected: _f.dateRange == _DateRange.last7,  onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.last7))),
            _chip(label: 'Last 30 days',selected: _f.dateRange == _DateRange.last30,onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.last30))),
            _chip(label: 'Custom',     selected: _f.dateRange == _DateRange.custom, onTap: () => setState(() => _f = _f.copyWith(dateRange: _DateRange.custom))),
          ]),
          if (_f.dateRange == _DateRange.custom) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _DateButton(label: 'From: ${_fmtDate(_f.customStart)}', onTap: () => _pickCustomDate(true), isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _DateButton(label: 'To: ${_fmtDate(_f.customEnd)}',     onTap: () => _pickCustomDate(false), isDark: isDark)),
            ]),
          ],
          const SizedBox(height: 20),

          // ── Store ────────────────────────────────────────────────────────
          if (_storeNames.isNotEmpty) ...[
            _sectionTitle('Store'),
            Wrap(children: [
              _chip(label: 'All stores', selected: _f.storeId == null,
                  onTap: () => setState(() => _f = _f.copyWith(storeId: null))),
              ..._storeMap.entries.map((e) => _chip(
                label: e.value,
                selected: _f.storeId == e.key,
                onTap: () => setState(() => _f = _f.copyWith(storeId: e.key)),
              )),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Service / Category ───────────────────────────────────────────
          if (_serviceNames.isNotEmpty) ...[
            _sectionTitle('Service / Category'),
            Wrap(children: [
              _chip(label: 'All services', selected: _f.serviceName == null,
                  onTap: () => setState(() => _f = _f.copyWith(serviceName: null))),
              ..._serviceNames.map((s) => _chip(
                label: s,
                selected: _f.serviceName == s,
                onTap: () => setState(() => _f = _f.copyWith(serviceName: s)),
              )),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Order Status ─────────────────────────────────────────────────
          _sectionTitle('Order Status'),
          Wrap(children: [
            _chip(label: 'All statuses', selected: _f.status == null,
                onTap: () => setState(() => _f = _f.copyWith(status: null))),
            ..._statuses.map((s) {
              final color = _statusChipColor(s);
              return _chip(
                label: s.replaceAll('_', ' '),
                selected: _f.status == s,
                color: color,
                onTap: () => setState(() => _f = _f.copyWith(status: s)),
              );
            }),
          ]),
          const SizedBox(height: 20),

          // ── Sort ─────────────────────────────────────────────────────────
          _sectionTitle('Sort By'),
          Wrap(children: _sortOptions.entries.map((e) => _chip(
            label: e.value,
            selected: _f.sortBy == e.key,
            onTap: () => setState(() => _f = _f.copyWith(sortBy: e.key)),
          )).toList()),
          const SizedBox(height: 28),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context, _f),
                child: Text('Apply Filters', style: GoogleFonts.alexandria(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
                )),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Color _statusChipColor(String s) {
  switch (s) {
    case 'pending':           return AppColors.primary;
    case 'confirmed':         return AppColors.info;
    case 'picked_up':
    case 'in_process':        return AppColors.warning;
    case 'ready':
    case 'out_for_delivery':  return AppColors.success;
    case 'delivered':         return AppColors.success;
    case 'cancelled':         return AppColors.error;
    default:                  return AppColors.primary;
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _DateButton({required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.alexandria(
          fontSize: 12,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        )),
        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
      ]),
    ),
  );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool showActive, isDark, isFiltered;
  const _EmptyState({required this.showActive, required this.isDark, required this.isFiltered});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(
        isFiltered ? Iconsax.search_normal : (showActive ? Iconsax.truck_fast : Iconsax.box),
        size: 72,
        color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
      ),
      const SizedBox(height: 16),
      Text(
        isFiltered ? 'No orders match your filters' : (showActive ? 'No active orders' : 'No completed orders'),
        style: GoogleFonts.alexandria(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        isFiltered ? 'Try adjusting or clearing your filters' : (showActive ? 'Tap + to book your first laundry service' : 'Completed orders will appear here'),
        style: GoogleFonts.alexandria(
          fontSize: 13,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

// ─── Tab toggle ───────────────────────────────────────────────────────────────

class _OrdersToggle extends StatelessWidget {
  final bool showActive, isDark;
  final ValueChanged<bool> onChanged;

  const _OrdersToggle({required this.showActive, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      _ToggleItem(label: 'Active Orders',  isActive: showActive,  onTap: () => onChanged(true),  isDark: isDark),
      const SizedBox(width: 8),
      _ToggleItem(label: 'Order History',  isActive: !showActive, onTap: () => onChanged(false), isDark: isDark),
    ]),
  );
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isActive, isDark;
  final VoidCallback onTap;

  const _ToggleItem({required this.label, required this.isActive, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.gradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Center(child: Text(label, style: GoogleFonts.alexandria(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 13,
          color: isActive ? Colors.white : (isDark ? AppColors.darkSubtext : Colors.grey.shade600),
        ))),
      ),
    ),
  );
}

// ─── All existing widgets below (unchanged) ───────────────────────────────────
// _ReorderSheet, _OrderCard, _ServiceImage, ReorderParams
// kept exactly as they were in the original file

class _ReorderSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  const _ReorderSheet({required this.order, required this.isDark});
  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  static const _times = ['10:00 AM','12:00 PM','02:00 PM','04:00 PM','06:00 PM'];
  late DateTime _pickupDate;
  late String _pickupTime;
  late DateTime _deliveryDate;
  late String _deliveryTime;
  bool get _isExpress => widget.order.serviceName.toLowerCase().contains('express');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _pickupDate = (widget.order.pickupDate != null && widget.order.pickupDate!.isAfter(today.subtract(const Duration(days: 1)))) ? widget.order.pickupDate! : today;
    _pickupTime = (widget.order.pickupTime != null && _times.contains(widget.order.pickupTime)) ? widget.order.pickupTime! : _times.first;
    _deliveryDate = _isExpress ? _pickupDate : _pickupDate.add(const Duration(days: 2));
    _deliveryTime = (widget.order.deliveryTime != null && _times.contains(widget.order.deliveryTime)) ? widget.order.deliveryTime! : _times.last;
  }

  void _onPickupDateChanged(DateTime d) => setState(() {
    _pickupDate = d;
    _deliveryDate = _isExpress ? d : d.add(const Duration(days: 2));
  });

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  InputDecoration _deco(String label, Color accent) => InputDecoration(
    labelText: label, filled: true,
    fillColor: widget.isDark ? AppColors.darkBackground : AppColors.lightBackground,
    labelStyle: TextStyle(color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: widget.isDark ? AppColors.darkSurface : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Reorder', style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 4),
        Text('Same service & store. Update your dates below.', style: GoogleFonts.alexandria(fontSize: 13, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.25))),
          child: Row(children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.serviceName, style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : AppColors.lightText)),
              Text('${o.storeName}  •  ${o.itemCount} pcs  •  ৳${o.totalPrice.toStringAsFixed(0)}', style: GoogleFonts.alexandria(fontSize: 11, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Pickup Schedule', style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(
            controller: TextEditingController(text: _fmt(_pickupDate)), readOnly: true,
            decoration: _deco('Date', AppColors.primary).copyWith(suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
              onPressed: () async {
                final p = await showDatePicker(context: context, initialDate: _pickupDate, firstDate: DateTime.now(), lastDate: DateTime(2100), builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!));
                if (p != null) _onPickupDateChanged(p);
              },
            )),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _pickupTime, decoration: _deco('Time', AppColors.primary),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            items: _times.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.alexandria(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _pickupTime = v); },
          )),
        ]),
        const SizedBox(height: 16),
        Text('Delivery Schedule', style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : AppColors.lightText)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextFormField(
            controller: TextEditingController(text: _fmt(_deliveryDate)), readOnly: true,
            decoration: _deco('Date', AppColors.success).copyWith(suffixIcon: _isExpress
                ? const Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 18)
                : IconButton(
              icon: const Icon(Icons.calendar_today_rounded, color: AppColors.success, size: 18),
              onPressed: () async {
                final min = _pickupDate.add(const Duration(days: 2));
                final p = await showDatePicker(context: context, initialDate: _deliveryDate.isBefore(min) ? min : _deliveryDate, firstDate: min, lastDate: DateTime(2100), builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.success)), child: child!));
                if (p != null) setState(() => _deliveryDate = p);
              },
            )),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            value: _deliveryTime, decoration: _deco('Time', AppColors.success),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.success),
            items: _times.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.alexandria(fontSize: 13)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _deliveryTime = v); },
          )),
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: Container(
          decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () => Navigator.pop(context, {'pickupDate': _pickupDate, 'pickupTime': _pickupTime, 'deliveryDate': _deliveryDate, 'deliveryTime': _deliveryTime}),
            child: Text('Confirm & Reorder', style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        )),
      ]),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final OrderEntity order;
  final bool isHistory, isDark;
  final VoidCallback onPress;
  const _OrderCard({super.key, required this.order, required this.isHistory, required this.isDark, required this.onPress});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return AppColors.primary;
      case 'confirmed': return AppColors.info;
      case 'picked_up': case 'in_process': return AppColors.warning;
      case 'ready': case 'out_for_delivery': return AppColors.success;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  double _progressFor(String s, double db) {
    final from = switch (s) {
      'pending' => 0.05, 'confirmed' => 0.1, 'picked_up' => 0.2,
      'in_process' => 0.4, 'ready' => 0.6, 'out_for_delivery' => 0.8,
      'delivered' => 1.0, _ => 0.0,
    };
    return db > from ? db : from;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _confirmCancel(BuildContext ctx) {
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Cancel Order?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
      content: Text('Cancel order #${widget.order.orderNumber}? This cannot be undone.', style: GoogleFonts.alexandria(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Keep Order', style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600))),
        TextButton(onPressed: () { Navigator.pop(dCtx); ctx.read<OrdersBloc>().add(OrderCancelRequested(widget.order.id)); }, child: Text('Yes, Cancel', style: GoogleFonts.alexandria(color: AppColors.error, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  bool _isStepDone(String status, int stepOrder) {
    final cur = switch (status) {
      'pending' || 'confirmed' => 1, 'picked_up' => 2, 'in_process' => 3,
      'ready' || 'out_for_delivery' => 4, 'delivered' => 5, _ => 0,
    };
    return stepOrder <= cur;
  }

  Future<void> _handleReorder(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _ReorderSheet(order: widget.order, isDark: widget.isDark));
    if (result == null || !context.mounted) return;
    context.push(RoutesName.placeOrdersNavigate, extra: ReorderParams(
      serviceId: widget.order.serviceId, storeId: widget.order.storeId,
      serviceName: widget.order.serviceName, storeName: widget.order.storeName,
      itemCount: widget.order.itemCount, totalPrice: widget.order.totalPrice,
      pickupAddress: widget.order.pickupAddress, deliveryAddress: widget.order.deliveryAddress,
      specialInstructions: widget.order.specialInstructions,
      pickupDate: result['pickupDate'] as DateTime, pickupTime: result['pickupTime'] as String,
      deliveryDate: result['deliveryDate'] as DateTime, deliveryTime: result['deliveryTime'] as String,
      paymentMethod: widget.order.paymentMethod,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final statusColor = _statusColor(o.status);
    final progress = _progressFor(o.status, o.progress);
    final sortedTimeline = List.of(o.timeline)..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return GestureDetector(
      onTap: widget.onPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
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
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.serviceName, style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 15, color: widget.isDark ? Colors.white : AppColors.lightText)),
              const SizedBox(height: 3),
              Text(o.storeName, style: GoogleFonts.alexandria(fontSize: 12, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
              const SizedBox(height: 5),
              Row(children: [
                Text('#${o.orderNumber}', style: GoogleFonts.alexandria(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(o.status.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.alexandria(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('৳${o.totalPrice.toStringAsFixed(0)}', style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              Text('${o.itemCount} pcs', style: GoogleFonts.alexandria(fontSize: 11, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
            ]),
          ]),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Container(height: 6, color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
            child: LayoutBuilder(builder: (_, c) => Align(alignment: Alignment.centerLeft,
              child: AnimatedContainer(duration: const Duration(milliseconds: 600), curve: Curves.easeOut,
                width: c.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(10)),
              ),
            )),
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.remove_red_eye_outlined, color: AppColors.primary, size: 18),
              onPressed: () => setState(() => _expanded = !_expanded),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              label: Text(_expanded ? 'Hide' : 'Details', style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            )),
            const SizedBox(width: 12),
            Expanded(child: widget.isHistory
                ? Container(
              decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay_outlined, color: Colors.white, size: 16),
                onPressed: () => _handleReorder(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                label: Text('Reorder', style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            )
                : BlocBuilder<OrdersBloc, OrdersState>(builder: (ctx, bState) {
              final cancelling = bState is OrderCancelling;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: cancelling ? null : () => _confirmCancel(ctx),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: cancelling ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                    label: Text(cancelling ? 'Cancelling…' : 'Cancel', style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, disabledBackgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              );
            }),
            ),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 20),
            Divider(color: widget.isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 12),
            Text('Order Timeline', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 14, color: widget.isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 12),
            if (sortedTimeline.isEmpty)
              Text('Timeline not available yet', style: GoogleFonts.alexandria(fontSize: 13, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext))
            else
              ...sortedTimeline.map((step) {
                final done = _isStepDone(o.status, step.stepOrder);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 14),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.primary.withOpacity(0.12) : (widget.isDark ? Colors.white12 : Colors.grey.shade100)),
                      child: Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined, color: done ? AppColors.primary : Colors.grey.shade400, size: 16),
                    ),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(step.title, style: GoogleFonts.alexandria(fontWeight: done ? FontWeight.bold : FontWeight.w500, color: done ? (widget.isDark ? Colors.white : Colors.black87) : Colors.grey.shade500, fontSize: 13)),
                      if (step.description != null && step.description!.isNotEmpty)
                        Text(step.description!, style: GoogleFonts.alexandria(fontSize: 11, color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
                      if (done && step.eventTime != null)
                        Text(_formatTime(step.eventTime!), style: GoogleFonts.alexandria(fontSize: 10, color: AppColors.primary.withOpacity(0.7))),
                    ])),
                  ]),
                );
              }),
          ],
        ]),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  const _ServiceImage({this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    height: 54, width: 54,
    decoration: BoxDecoration(
      gradient: imageUrl == null ? AppColors.gradient : null,
      color: imageUrl != null ? (isDark ? AppColors.darkSurface : Colors.grey.shade100) : null,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(16),
      child: imageUrl != null
          ? CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover,
        placeholder: (_, __) => Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withOpacity(0.5)))),
        errorWidget: (_, __, ___) => Container(decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 28)),
      )
          : const Icon(Icons.local_laundry_service, color: Colors.white, size: 28),
    ),
  );
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