import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/order_status.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/order_entity.dart';
import '../../models/order_filter.dart';

class OrderFilterSheet extends StatefulWidget {
  final OrderFilter current;
  final List<OrderEntity> allOrders;

  const OrderFilterSheet({
    super.key,
    required this.current,
    required this.allOrders,
  });

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  late OrderFilter _f;
  late final Map<String, String> _storeMap;
  late final List<String> _serviceNames;
  late final List<String> _availableStatuses;

  static const _sortOptions = {
    'newest': 'Newest first',
    'oldest': 'Oldest first',
    'price_asc': 'Price: Low → High',
    'price_desc': 'Price: High → Low',
  };

  @override
  void initState() {
    super.initState();
    _f = widget.current;

    // Extract unique data from existing orders for filter chips
    _storeMap = {for (final o in widget.allOrders) o.storeId: o.storeName};
    _serviceNames = widget.allOrders.map((o) => o.serviceName).toSet().toList()
      ..sort();
    _availableStatuses =
        widget.allOrders
            .map((o) => OrderStatus.getDisplayStatus(o.status))
            .toSet()
            .toList()
          ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildHeader(isDark),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSectionTitle('Date Range', Iconsax.calendar, isDark),
                    _buildDateRangeChips(isDark),

                    if (_storeMap.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Store Location',
                        Iconsax.shop,
                        isDark,
                      ),
                      _buildStoreChips(isDark),
                    ],

                    if (_serviceNames.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Service Category',
                        Iconsax.category,
                        isDark,
                      ),
                      _buildServiceChips(isDark),
                    ],

                    _buildSectionTitle('Order Status', Iconsax.status, isDark),
                    _buildStatusChips(isDark),

                    _buildSectionTitle('Sort Results', Iconsax.sort, isDark),
                    _buildSortChips(isDark),

                    const SizedBox(height: 24),
                    AppGradientButton(
                      label: 'Apply Filters',
                      onPressed: () => Navigator.pop(context, _f),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          AppSheetHandle(isDark: isDark), //
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Filter Orders', style: AppTextStyles.appBarTitle),
              const Spacer(),
              if (_f.isActive)
                GestureDetector(
                  onTap: () => setState(() => _f = const OrderFilter()),
                  child: Text(
                    'Reset',
                    style: AppTextStyles.captionMedium(
                      isDark,
                    ).copyWith(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String t, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          AppSectionLabel(text: t, isDark: isDark), //
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradient : null,
          color: selected
              ? null
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white10 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionMedium(
            selected,
          ).copyWith(color: selected ? Colors.white : null),
        ),
      ),
    );
  }

  // Chip grouping helpers...
  Widget _buildDateRangeChips(bool isDark) {
    return Wrap(
      children: [
        _buildChip(
          label: 'All time',
          selected: _f.dateRange == DateRange.all,
          isDark: isDark,
          onTap: () =>
              setState(() => _f = _f.copyWith(dateRange: DateRange.all)),
        ),
        _buildChip(
          label: 'Today',
          selected: _f.dateRange == DateRange.today,
          isDark: isDark,
          onTap: () =>
              setState(() => _f = _f.copyWith(dateRange: DateRange.today)),
        ),
        // Add other ranges similarly from your OrderFilter model
      ],
    );
  }

  Widget _buildStoreChips(bool isDark) {
    return Wrap(
      children: [
        _buildChip(
          label: 'All stores',
          selected: _f.storeId == null,
          isDark: isDark,
          onTap: () => setState(() => _f = _f.copyWith(storeId: null)),
        ),
        ..._storeMap.entries.map(
          (e) => _buildChip(
            label: e.value,
            selected: _f.storeId == e.key,
            isDark: isDark,
            onTap: () => setState(() => _f = _f.copyWith(storeId: e.key)),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChips(bool isDark) {
    return Wrap(
      children: [
        _buildChip(
          label: 'All services',
          selected: _f.serviceName == null,
          isDark: isDark,
          onTap: () => setState(() => _f = _f.copyWith(serviceName: null)),
        ),
        ..._serviceNames.map(
          (s) => _buildChip(
            label: s,
            selected: _f.serviceName == s,
            isDark: isDark,
            onTap: () => setState(() => _f = _f.copyWith(serviceName: s)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips(bool isDark) {
    return Wrap(
      children: [
        _buildChip(
          label: 'All statuses',
          selected: _f.status == null,
          isDark: isDark,
          onTap: () => setState(() => _f = _f.copyWith(status: null)),
        ),
        ..._availableStatuses.map(
          (s) => _buildChip(
            label: OrderStatus.format(s),
            selected: _f.status == s,
            isDark: isDark,
            onTap: () => setState(() => _f = _f.copyWith(status: s)),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChips(bool isDark) {
    return Wrap(
      children: _sortOptions.entries
          .map(
            (e) => _buildChip(
              label: e.value,
              selected: _f.sortBy == e.key,
              isDark: isDark,
              onTap: () => setState(() => _f = _f.copyWith(sortBy: e.key)),
            ),
          )
          .toList(),
    );
  }
}
