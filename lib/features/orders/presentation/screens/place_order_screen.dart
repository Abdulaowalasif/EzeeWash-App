// lib/features/orders/screens/place_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/revponsive.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';

class _ServiceOption {
  final String id; // real UUID from Supabase — never hardcode this
  final String title;
  final String subtitle;
  final double price;
  final String duration;
  final String category;

  const _ServiceOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.category,
  });

  factory _ServiceOption.fromJson(Map<String, dynamic> j) => _ServiceOption(
    id: j['id'] as String,
    title: j['title'] as String,
    subtitle: j['description'] as String? ?? '',
    price: (j['price'] as num).toDouble(),
    duration: j['duration'] as String? ?? '',
    category: j['category'] as String? ?? '',
  );

  IconData get icon {
    switch (category) {
      case 'Dry Clean':   return Iconsax.wind;
      case 'Iron & Press': return Iconsax.flash_1;
      case 'Express':     return Iconsax.timer_1;
      case 'Steam Clean': return Iconsax.cloud;
      case 'Suit Wash':   return Iconsax.brush_2;
      default:            return Iconsax.drop;
    }
  }
}

class _StoreOption {
  final String id; // real UUID from Supabase — never hardcode this
  final String name;
  final String address;
  final String distance;

  const _StoreOption({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
  });

  factory _StoreOption.fromJson(Map<String, dynamic> j) => _StoreOption(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String,
    distance: '${j['distance_km'] ?? '?'} km',
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});
  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  // Data loading (replaces the old hardcoded static lists)
  bool _dataLoading = true;
  String? _dataError;
  List<_ServiceOption> _services = [];
  List<_StoreOption> _stores = [];

  // Wizard state
  int _step = 1;
  int? _serviceIdx;
  int? _storeIdx;
  DateTime? _pickupDate;
  String _pickupTime = 'Select time';
  DateTime? _deliveryDate;
  String _deliveryTime = 'Select time';
  final _addrCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _addrCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── FIX 5 cont.: load real UUIDs from Supabase ────────────────────────────
  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final svcsRaw = await client
          .from(AppConstants.servicesTable)
          .select()
          .eq('is_active', true)
          .order('category');
      final strsRaw = await client
          .from(AppConstants.storesTable)
          .select()
          .eq('is_active', true)
          .order('distance_km');

      if (!mounted) return;
      setState(() {
        _services =
            (svcsRaw as List).map((e) => _ServiceOption.fromJson(e)).toList();
        _stores =
            (strsRaw as List).map((e) => _StoreOption.fromJson(e)).toList();
        _dataLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dataError = e.toString();
        _dataLoading = false;
      });
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 1: return _serviceIdx != null;
      case 2: return _storeIdx != null;
      case 3:
        return _pickupDate != null &&
            _deliveryDate != null &&
            _pickupTime != 'Select time' &&
            _deliveryTime != 'Select time';
      case 4: return _addrCtrl.text.trim().isNotEmpty;
      default: return false;
    }
  }

  // ── FIX 4: wrap in PlaceOrderParams before passing to event ───────────────
  //   was: OrderPlaceRequested(serviceId: ..., storeId: ..., ...)
  //   The event constructor is OrderPlaceRequested(PlaceOrderParams params).
  //   Passing named params directly to the event causes a compile error:
  //   "The named parameter 'serviceId' isn't defined for OrderPlaceRequested."
  void _onConfirm() {
    if (_serviceIdx == null || _storeIdx == null) return;
    final svc   = _services[_serviceIdx!];
    final store = _stores[_storeIdx!];

    context.read<OrdersBloc>().add(
      OrderPlaceRequested(
        PlaceOrderParams(
          serviceId:  svc.id,   // real UUID — FK satisfied
          storeId:    store.id, // real UUID — FK satisfied
          itemCount:  1,
          totalPrice: svc.price,
          pickupAddress:   _addrCtrl.text.trim(),
          deliveryAddress: _addrCtrl.text.trim(),
          pickupDate:   _pickupDate,
          pickupTime:   _pickupTime == 'Select time' ? null : _pickupTime,
          deliveryDate: _deliveryDate,
          deliveryTime: _deliveryTime == 'Select time' ? null : _deliveryTime,
          specialInstructions: _noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Loading state
    if (_dataLoading) {
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state with retry
    if (_dataError != null) {
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 52),
                const SizedBox(height: 14),
                Text(_dataError!,
                    style: GoogleFonts.alexandria(
                        color: AppColors.error, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () {
                    setState(() {
                      _dataError = null;
                      _dataLoading = true;
                    });
                    _loadData();
                  },
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
              ],
            ),
          ),
        ),
      );
    }

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          // Use go() so the wizard is removed from the back stack
          context.go(
            RoutesName.confirmedOrdersNavigate,
            extra: state.orderNumber,
          );
        } else if (state is OrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.alexandria(fontSize: 13)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text('Book Service',
              style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context)),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _StepProgressCard(step: _step, isDark: isDark),
                  const SizedBox(height: 20),

                  // Step header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_stepTitle,
                            style: GoogleFonts.alexandria(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightText)),
                        const SizedBox(height: 4),
                        Text(_stepSubtitle,
                            style: GoogleFonts.alexandria(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkSubtext
                                    : AppColors.lightSubtext)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            ),
                        child: _buildStepContent(isDark),
                      ),
                    ),
                  ),

                  // Bottom buttons
                  _BottomActions(
                    step: _step,
                    enabled: _canProceed,
                    isDark: isDark,
                    isLoading: context.watch<OrdersBloc>().state
                    is OrderPlacing,
                    onBack: () {
                      if (_step == 1) {
                        context.pop();
                      } else {
                        setState(() => _step--);
                      }
                    },
                    onNext: () {
                      if (_step < 4) {
                        setState(() => _step++);
                      } else {
                        _onConfirm();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _stepTitle =>
      const ['Select Service', 'Select Store', 'Schedule Service',
        'Final Details'][_step - 1];

  String get _stepSubtitle => const [
    'Choose the service that best fits your needs',
    'Select a nearby store location',
    'Choose your pickup and delivery times',
    'Review your order and add instructions',
  ][_step - 1];

  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 1:
        return Column(
          key: const ValueKey(1),
          children: List.generate(
            _services.length,
                (i) => _ServiceCard(
              service: _services[i],
              isSelected: _serviceIdx == i,
              isDark: isDark,
              onTap: () => setState(() => _serviceIdx = i),
            ),
          ),
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          children: List.generate(
            _stores.length,
                (i) => _StoreCard(
              store: _stores[i],
              isSelected: _storeIdx == i,
              isDark: isDark,
              onTap: () => setState(() => _storeIdx = i),
            ),
          ),
        );
      case 3:
        return _ScheduleStep(
          key: const ValueKey(3),
          pickupDate: _pickupDate,
          pickupTime: _pickupTime,
          deliveryDate: _deliveryDate,
          deliveryTime: _deliveryTime,
          isDark: isDark,
          onPickupDate: (d) => setState(() => _pickupDate = d),
          onPickupTime: (t) => setState(() => _pickupTime = t),
          onDeliveryDate: (d) => setState(() => _deliveryDate = d),
          onDeliveryTime: (t) => setState(() => _deliveryTime = t),
        );
      case 4:
        if (_serviceIdx == null || _storeIdx == null) {
          return const SizedBox.shrink();
        }
        return _FinalStep(
          key: const ValueKey(4),
          addrCtrl: _addrCtrl,
          noteCtrl: _noteCtrl,
          service: _services[_serviceIdx!],
          store: _stores[_storeIdx!],
          pickupDate: _pickupDate!,
          pickupTime: _pickupTime,
          deliveryDate: _deliveryDate!,
          deliveryTime: _deliveryTime,
          isDark: isDark,
          onChanged: () => setState(() {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Step Progress ────────────────────────────────────────────────────────────

class _StepProgressCard extends StatelessWidget {
  final int step;
  final bool isDark;
  const _StepProgressCard({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: List.generate(7, (i) {
          if (i.isEven) {
            final s = i ~/ 2 + 1;
            final done = s < step;
            final active = s == step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: (done || active) ? AppColors.gradient : null,
                color: (done || active)
                    ? null
                    : (isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text('$s',
                    style: GoogleFonts.alexandria(
                        color: active
                            ? Colors.white
                            : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            );
          } else {
            final lineIdx = i ~/ 2 + 1;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: lineIdx < step ? AppColors.gradient : null,
                  color: lineIdx < step
                      ? null
                      : (isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}

// ─── Step 1: Service cards ────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceOption service;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _ServiceCard(
      {required this.service,
        required this.isSelected,
        required this.isDark,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.07))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ]
              : (isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.gradient : null,
                color: isSelected
                    ? null
                    : (isDark
                    ? Colors.grey.shade800
                    : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(service.icon,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500),
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title,
                      style: GoogleFonts.alexandria(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                          isDark ? Colors.white : AppColors.lightText)),
                  const SizedBox(height: 3),
                  Text(service.subtitle,
                      style: GoogleFonts.alexandria(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('৳${service.price.toStringAsFixed(0)}',
                          style: GoogleFonts.alexandria(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(service.duration,
                            style: GoogleFonts.alexandria(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.gradient),
                  child:
                  const Icon(Icons.check, color: Colors.white, size: 16)),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Store cards ──────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final _StoreOption store;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _StoreCard(
      {required this.store,
        required this.isSelected,
        required this.isDark,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.primary.withOpacity(0.07))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ]
              : (isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.gradient : null,
                color: isSelected
                    ? null
                    : (isDark
                    ? Colors.grey.shade800
                    : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Iconsax.shop,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade500),
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name,
                      style: GoogleFonts.alexandria(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                          isDark ? Colors.white : AppColors.lightText)),
                  const SizedBox(height: 3),
                  Text(store.address,
                      style: GoogleFonts.alexandria(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(store.distance,
                            style: GoogleFonts.alexandria(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.gradient),
                  child:
                  const Icon(Icons.check, color: Colors.white, size: 16)),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Schedule ─────────────────────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  final DateTime? pickupDate, deliveryDate;
  final String pickupTime, deliveryTime;
  final bool isDark;
  final ValueChanged<DateTime> onPickupDate, onDeliveryDate;
  final ValueChanged<String> onPickupTime, onDeliveryTime;

  const _ScheduleStep({
    super.key,
    required this.pickupDate,
    required this.deliveryDate,
    required this.pickupTime,
    required this.deliveryTime,
    required this.isDark,
    required this.onPickupDate,
    required this.onDeliveryDate,
    required this.onPickupTime,
    required this.onDeliveryTime,
  });

  static const _times = [
    'Select time',
    '10:00 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
    '06:00 PM',
  ];

  String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _ScheduleCard(
        title: 'Pickup Schedule',
        icon: Iconsax.arrow_up_3,
        gradient: AppColors.gradient,
        accentColor: AppColors.primary,
        date: pickupDate,
        time: pickupTime,
        times: _times,
        isDark: isDark,
        formatDate: _fmt,
        onDate: onPickupDate,
        onTime: onPickupTime,
      ),
      const SizedBox(height: 20),
      _ScheduleCard(
        title: 'Delivery Schedule',
        icon: Iconsax.arrow_down_2,
        gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF059669)]),
        accentColor: AppColors.success,
        date: deliveryDate,
        time: deliveryTime,
        times: _times,
        isDark: isDark,
        formatDate: _fmt,
        onDate: onDeliveryDate,
        onTime: onDeliveryTime,
      ),
    ]);
  }
}

class _ScheduleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final DateTime? date;
  final String time;
  final List<String> times;
  final bool isDark;
  final String Function(DateTime?) formatDate;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTime;

  const _ScheduleCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.date,
    required this.time,
    required this.times,
    required this.isDark,
    required this.formatDate,
    required this.onDate,
    required this.onTime,
  });

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor:
    isDark ? AppColors.darkBackground : AppColors.lightBackground,
    labelStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentColor, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
            isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 18)),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText)),
          ]),
          const SizedBox(height: 18),
          TextFormField(
            controller: TextEditingController(text: formatDate(date)),
            decoration: _deco('Date').copyWith(
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today_rounded,
                    color: accentColor, size: 20),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme:
                          ColorScheme.light(primary: accentColor)),
                      child: child!,
                    ),
                  );
                  if (picked != null) onDate(picked);
                },
              ),
            ),
            readOnly: true,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: time,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: accentColor),
            decoration: _deco('Time'),
            items: times
                .map((t) => DropdownMenuItem(
                value: t,
                child:
                Text(t, style: GoogleFonts.alexandria(fontSize: 14))))
                .toList(),
            onChanged: (v) {
              if (v != null) onTime(v);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Step 4: Final details ────────────────────────────────────────────────────

class _FinalStep extends StatelessWidget {
  final TextEditingController addrCtrl, noteCtrl;
  final _ServiceOption service;
  final _StoreOption store;
  final DateTime pickupDate, deliveryDate;
  final String pickupTime, deliveryTime;
  final bool isDark;
  final VoidCallback onChanged;

  const _FinalStep({
    super.key,
    required this.addrCtrl,
    required this.noteCtrl,
    required this.service,
    required this.store,
    required this.pickupDate,
    required this.pickupTime,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.isDark,
    required this.onChanged,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.alexandria(
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        fontSize: 13),
    prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
    filled: true,
    fillColor:
    isDark ? AppColors.darkBackground : AppColors.lightBackground,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
        const BorderSide(color: AppColors.primary, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Address + instructions
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pickup / Delivery Address',
                style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 12),
            TextField(
                controller: addrCtrl,
                maxLines: 2,
                onChanged: (_) => onChanged(),
                decoration: _deco('Enter your complete address',
                    Icons.location_on_outlined)),
            const SizedBox(height: 20),
            Text('Special Instructions',
                style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 12),
            TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: _deco('Any special care instructions…',
                    Icons.note_alt_outlined)),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Order summary
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.01),
          ]),
          color: isDark ? const Color(0xFF1A1A2E) : null,
          borderRadius: BorderRadius.circular(22),
          border:
          Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Order Summary',
                  style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.lightText)),
            ]),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Service',  value: service.title,          isDark: isDark),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Store',    value: store.name,             isDark: isDark),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Pickup',   value: '${_fmt(pickupDate)} at $pickupTime',   isDark: isDark),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Delivery', value: '${_fmt(deliveryDate)} at $deliveryTime', isDark: isDark),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                  color: isDark
                      ? Colors.white24
                      : AppColors.primary.withOpacity(0.2),
                  thickness: 1.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.lightText)),
                Text('৳${service.price.toStringAsFixed(0)}',
                    style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _SummaryRow(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.alexandria(
                color: isDark
                    ? AppColors.darkSubtext
                    : AppColors.lightSubtext,
                fontSize: 13)),
        Flexible(
          child: Text(value,
              style: GoogleFonts.alexandria(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final int step;
  final bool enabled, isDark, isLoading;
  final VoidCallback onBack, onNext;

  const _BottomActions({
    required this.step,
    required this.enabled,
    required this.isDark,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 28),
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(step == 1 ? 'Cancel' : 'Back',
                style: GoogleFonts.alexandria(
                    color:
                    isDark ? Colors.white70 : AppColors.lightSubtext,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.gradient : null,
              color: enabled
                  ? null
                  : (isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled
                  ? [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: enabled && !isLoading ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isLoading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text(step == 4 ? 'Confirm Booking' : 'Next',
                  style: GoogleFonts.alexandria(
                      color: enabled
                          ? Colors.white
                          : (isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade400),
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }
}