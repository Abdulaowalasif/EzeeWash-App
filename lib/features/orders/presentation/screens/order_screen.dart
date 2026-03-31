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

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 10,
              Responsive.horizontalPadding(context), 10,
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Row(children: [
              Text('My Orders',
                  style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listenWhen: (_, s) => s is OrderCancelled || s is OrdersError,
        listener: (context, state) {
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Order cancelled.',
                  style: GoogleFonts.alexandria(fontSize: 13)),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          } else if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.alexandria(fontSize: 13)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 52),
                  const SizedBox(height: 14),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () => context
                        .read<OrdersBloc>()
                        .add(const OrdersLoadRequested()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    label: Text('Retry',
                        style: GoogleFonts.alexandria(
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            );
          }
          if (state is OrdersLoaded) {
            return _OrdersBody(state: state, isDark: isDark);
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
                offset: const Offset(0, 6)),
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

// ─── Orders body ──────────────────────────────────────────────────────────────

class _OrdersBody extends StatelessWidget {
  final OrdersLoaded state;
  final bool isDark;
  const _OrdersBody({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Build both lists independently from the full order list.
    final activeOrders = state.orders
        .where((o) => o.status != 'delivered' && o.status != 'cancelled')
        .toList();
    final historyOrders = state.orders
        .where((o) => o.status == 'delivered' || o.status == 'cancelled')
        .toList();

    final displayed =
    state.showActive ? activeOrders : historyOrders;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 10,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: Column(children: [
            _OrdersToggle(
              showActive: state.showActive,
              isDark: isDark,
              onChanged: (active) => context
                  .read<OrdersBloc>()
                  .add(OrdersFilterToggled(active)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: displayed.isEmpty
                  ? _EmptyState(
                  showActive: state.showActive, isDark: isDark)
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final order = displayed[i];

                  // Format: "<tab>_<orderId>_<status>"
                  final tab = state.showActive ? 'a' : 'h';
                  return _OrderCard(
                    key: ValueKey(
                        '${tab}_${order.id}_${order.status}'),
                    order: order,
                    isHistory: !state.showActive,
                    isDark: isDark,
                    onPress: () => context.push(
                      RoutesName.trackOrdersNavigate,
                      extra: order.id,
                    ),
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool showActive, isDark;
  const _EmptyState({required this.showActive, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(showActive ? Iconsax.truck_fast : Iconsax.box,
          size: 72,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
      const SizedBox(height: 16),
      Text(
        showActive ? 'No active orders' : 'No completed orders',
        style: GoogleFonts.alexandria(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
      ),
      const SizedBox(height: 8),
      Text(
        showActive
            ? 'Tap + to book your first laundry service'
            : 'Completed orders will appear here',
        style: GoogleFonts.alexandria(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

// ─── Tab toggle ───────────────────────────────────────────────────────────────

class _OrdersToggle extends StatelessWidget {
  final bool showActive, isDark;
  final ValueChanged<bool> onChanged;
  const _OrdersToggle(
      {required this.showActive,
        required this.isDark,
        required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
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
    child: Row(children: [
      _ToggleItem(
          label: 'Active Orders',
          isActive: showActive,
          onTap: () => onChanged(true),
          isDark: isDark),
      const SizedBox(width: 8),
      _ToggleItem(
          label: 'Order History',
          isActive: !showActive,
          onTap: () => onChanged(false),
          isDark: isDark),
    ]),
  );
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isActive, isDark;
  final VoidCallback onTap;
  const _ToggleItem(
      {required this.label,
        required this.isActive,
        required this.onTap,
        required this.isDark});

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
          boxShadow: isActive
              ? [BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))]
              : [],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.alexandria(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: isActive
                      ? Colors.white
                      : (isDark
                      ? AppColors.darkSubtext
                      : Colors.grey.shade600))),
        ),
      ),
    ),
  );
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final OrderEntity order;
  final bool isHistory, isDark;
  final VoidCallback onPress;

  const _OrderCard({
    super.key,
    required this.order,
    required this.isHistory,
    required this.isDark,
    required this.onPress,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':          return AppColors.primary;
      case 'confirmed':        return AppColors.info;
      case 'picked_up':
      case 'in_process':       return AppColors.warning;
      case 'ready':
      case 'out_for_delivery': return AppColors.success;
      case 'delivered':        return AppColors.success;
      case 'cancelled':        return AppColors.error;
      default:                 return AppColors.primary;
    }
  }

  double _progressFor(String s, double dbProgress) {
    final fromStatus = () {
      switch (s) {
        case 'pending':          return 0.05;
        case 'confirmed':        return 0.1;
        case 'picked_up':        return 0.2;
        case 'in_process':       return 0.4;
        case 'ready':            return 0.6;
        case 'out_for_delivery': return 0.8;
        case 'delivered':        return 1.0;
        default:                 return 0.0;
      }
    }();
    return dbProgress > fromStatus ? dbProgress : fromStatus;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m      = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m $period';
  }

  void _confirmCancel(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Order?',
            style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
        content: Text(
          'Cancel order #${widget.order.orderNumber}? This cannot be undone.',
          style: GoogleFonts.alexandria(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Keep Order',
                style: GoogleFonts.alexandria(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ctx.read<OrdersBloc>()
                  .add(OrderCancelRequested(widget.order.id));
            },
            child: Text('Yes, Cancel',
                style: GoogleFonts.alexandria(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Derived step completion directly from the order status string
  bool _isStepDone(String status, int stepOrder) {
    int currentStep = 0;
    switch (status) {
      case 'pending':
      case 'confirmed':        currentStep = 1; break;
      case 'picked_up':        currentStep = 2; break;
      case 'in_process':       currentStep = 3; break;
      case 'ready':
      case 'out_for_delivery': currentStep = 4; break;
      case 'delivered':        currentStep = 5; break;
    }
    return stepOrder <= currentStep;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final o           = widget.order;
    final statusColor = _statusColor(o.status);
    final progress    = _progressFor(o.status, o.progress);

    // Sort timeline locally to ensure steps render in perfect sequential order
    final sortedTimeline = List.of(o.timeline)
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    return GestureDetector(
      onTap: widget.onPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: widget.isDark
              ? []
              : [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ────────────────────────────────────────────────
              Row(children: [
                Container(
                  height: 54, width: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: _ServiceImage(
                      imageUrl: o.serviceImageUrl, isDark: widget.isDark),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('#${o.orderNumber}',
                      style: GoogleFonts.alexandria(
                          fontWeight: FontWeight.bold, fontSize: 15,
                          color: widget.isDark
                              ? Colors.white : AppColors.lightText)),
                  const SizedBox(height: 2),
                  Text(o.serviceName,
                      style: GoogleFonts.alexandria(
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.white70 : Colors.black87)),
                  Text(o.storeName,
                      style: GoogleFonts.alexandria(
                          fontSize: 11,
                          color: widget.isDark
                              ? AppColors.darkSubtext : AppColors.lightSubtext)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      o.status.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.alexandria(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('৳${o.totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.alexandria(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary)),
                ]),
              ]),

              const SizedBox(height: 16),

              // ── Progress bar ─────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 6,
                  color: widget.isDark
                      ? Colors.white12 : Colors.grey.shade200,
                  child: LayoutBuilder(
                    builder: (_, constraints) => Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: constraints.maxWidth *
                            progress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Action buttons ───────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.remove_red_eye_outlined,
                      color: AppColors.primary, size: 18,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: Text(_expanded ? 'Hide' : 'Details',
                        style: GoogleFonts.alexandria(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.isHistory
                  // ── Reorder ───────────────────────────────────
                      ? Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.replay_outlined,
                          color: Colors.white, size: 16),
                      onPressed: () =>
                          context.push(RoutesName.placeOrdersNavigate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text('Reorder',
                          style: GoogleFonts.alexandria(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                  )
                  // ── Cancel ────────────────────────────────────
                      : BlocBuilder<OrdersBloc, OrdersState>(
                    builder: (ctx, bState) {
                      final cancelling = bState is OrderCancelling;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: cancelling
                            ? null
                            : () => _confirmCancel(ctx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(
                                color: AppColors.error.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: cancelling
                                ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                                : const Icon(Icons.cancel_outlined,
                                color: Colors.white, size: 16),
                            label: Text(
                                cancelling ? 'Cancelling…' : 'Cancel',
                                style: GoogleFonts.alexandria(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]),

              // ── Timeline expansion ───────────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 20),
                Divider(color: widget.isDark
                    ? Colors.white12 : Colors.grey.shade200),
                const SizedBox(height: 12),
                Text('Order Timeline',
                    style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: widget.isDark
                            ? Colors.white : AppColors.lightText)),
                const SizedBox(height: 12),
                if (sortedTimeline.isEmpty)
                  Text('Timeline not available yet',
                      style: GoogleFonts.alexandria(
                          fontSize: 13,
                          color: widget.isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext))
                else
                  ...sortedTimeline.map((step) {
                    // Check dynamically using the new helper
                    final isStepDone = _isStepDone(o.status, step.stepOrder);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 14),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isStepDone
                                    ? AppColors.primary.withOpacity(0.12)
                                    : (widget.isDark
                                    ? Colors.white12
                                    : Colors.grey.shade100),
                              ),
                              child: Icon(
                                isStepDone
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isStepDone
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                size: 16,
                              ),
                            ),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(step.title,
                                      style: GoogleFonts.alexandria(
                                          fontWeight: isStepDone
                                              ? FontWeight.bold : FontWeight.w500,
                                          color: isStepDone
                                              ? (widget.isDark
                                              ? Colors.white : Colors.black87)
                                              : Colors.grey.shade500,
                                          fontSize: 13)),
                                  if (step.description != null &&
                                      step.description!.isNotEmpty)
                                    Text(step.description!,
                                        style: GoogleFonts.alexandria(
                                            fontSize: 11,
                                            color: widget.isDark
                                                ? AppColors.darkSubtext
                                                : AppColors.lightSubtext)),
                                  if (isStepDone && step.eventTime != null)
                                    Text(_formatTime(step.eventTime!),
                                        style: GoogleFonts.alexandria(
                                            fontSize: 10,
                                            color: AppColors.primary.withOpacity(0.7))),
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

// ─── Service image ────────────────────────────────────────────────────────────

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  const _ServiceImage({this.imageUrl, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    height: 54, width: 54,
    decoration: BoxDecoration(
      gradient: imageUrl == null ? AppColors.gradient : null,
      color: imageUrl != null
          ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
          : null,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: AppColors.primary.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 3))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imageUrl != null
          ? CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary.withOpacity(0.5)),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.local_laundry_service,
              color: Colors.white, size: 28),
        ),
      )
          : const Icon(Icons.local_laundry_service,
          color: Colors.white, size: 28),
    ),
  );
}