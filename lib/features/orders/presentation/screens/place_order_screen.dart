// lib/features/orders/screens/place_order_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';

// ─── Local DB models ──────────────────────────────────────────────────────────

class _ServiceItem {
  final String id, title, subtitle, duration, category;
  final double price;
  final String? imageUrl; // from services.image_url

  const _ServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.category,
    this.imageUrl,
  });

  factory _ServiceItem.fromJson(Map<String, dynamic> j) => _ServiceItem(
    id: j['id'] as String,
    title: j['title'] as String,
    subtitle: j['description'] as String? ?? '',
    price: (j['price'] as num).toDouble(),
    duration: j['duration'] as String? ?? '',
    category: j['category'] as String? ?? '',
    imageUrl: j['image_url'] as String?,
  );
}

class _StoreItem {
  final String id, name, address, distance;
  final String? logoUrl; // from stores.logo_url

  const _StoreItem({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.logoUrl,
  });

  factory _StoreItem.fromJson(Map<String, dynamic> j) => _StoreItem(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String,
    distance: '${j['distance_km'] ?? '?'} km',
    logoUrl: j['logo_url'] as String?,
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlaceOrderScreen extends StatefulWidget {
  /// When non-null, the service with this ID is pre-selected and step 1 is skipped.
  final String? preSelectedServiceId;

  const PlaceOrderScreen({super.key, this.preSelectedServiceId});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  bool _dataLoading = true;
  String? _dataError;
  List<_ServiceItem> _services = [];
  List<_StoreItem> _stores = [];

  int _step = 1;
  int? _serviceIdx;
  int? _storeIdx;
  DateTime? _pickupDate;
  String _pickupTime = 'Select time';
  DateTime? _deliveryDate;
  String _deliveryTime = 'Select time';
  final _addrCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  bool _stripeLoading = false;
  String? _stripeError;
  String? _placedOrderNumber;

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

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final svcs = await client
          .from(AppConstants.servicesTable)
          .select()
          .eq('is_active', true)
          .order('category');
      final strs = await client
          .from(AppConstants.storesTable)
          .select()
          .eq('is_active', true)
          .order('distance_km');

      if (mounted) {
        final services =
        (svcs as List).map((e) => _ServiceItem.fromJson(e)).toList();
        final stores =
        (strs as List).map((e) => _StoreItem.fromJson(e)).toList();

        // Auto-select the pre-selected service if one was passed
        int? preIdx;
        if (widget.preSelectedServiceId != null) {
          final idx =
          services.indexWhere((s) => s.id == widget.preSelectedServiceId);
          if (idx != -1) preIdx = idx;
        }

        setState(() {
          _services = services;
          _stores = stores;
          _serviceIdx = preIdx;
          _dataLoading = false;
          // Skip step 1 entirely when a service is pre-selected
          if (preIdx != null) _step = 2;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _dataError = e.toString();
          _dataLoading = false;
        });
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 1:
        return _serviceIdx != null;
      case 2:
        return _storeIdx != null;
      case 3:
        return _pickupDate != null &&
            _deliveryDate != null &&
            _pickupTime != 'Select time' &&
            _deliveryTime != 'Select time';
      case 4:
        return _addrCtrl.text.trim().isNotEmpty;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _placeOrder() {
    if (_serviceIdx == null || _storeIdx == null) return;
    final svc = _services[_serviceIdx!];
    final store = _stores[_storeIdx!];
    context.read<OrdersBloc>().add(
      OrderPlaceRequested(
        PlaceOrderParams(
          serviceId: svc.id,
          storeId: store.id,
          itemCount: 1,
          totalPrice: svc.price,
          pickupAddress: _addrCtrl.text.trim(),
          deliveryAddress: _addrCtrl.text.trim(),
          pickupDate: _pickupDate,
          pickupTime: _pickupTime == 'Select time' ? null : _pickupTime,
          deliveryDate: _deliveryDate,
          deliveryTime: _deliveryTime == 'Select time' ? null : _deliveryTime,
          specialInstructions:
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          paymentMethod: _paymentMethod,
        ),
      ),
    );
  }

  Future<void> _handleStripePayment(String orderNumber) async {
    if (!mounted) return;
    setState(() {
      _stripeLoading = true;
      _stripeError = null;
    });
    try {
      final svc = _services[_serviceIdx!];
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': svc.price,
          'currency': 'bdt',
          'orderId': orderNumber,
          'description': 'EzeeWash - ${svc.title}',
        },
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Payment setup failed');
      }

      final clientSecret = response.data['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'EzeeWash',
          style: Theme.of(context).brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: AppColors.primary),
            shapes: PaymentSheetShape(borderRadius: 12),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        context.go(
          '${RoutesName.orders}/${RoutesName.confirmedOrders}',
          extra: orderNumber,
        );
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (mounted) setState(() => _stripeLoading = false);
        _showSnack(
          'Payment cancelled. Order saved — pay later from Orders.',
          isError: false,
        );
      } else {
        if (mounted)
          setState(() {
            _stripeLoading = false;
            _stripeError = e.error.localizedMessage;
          });
        _showSnack(e.error.localizedMessage ?? 'Payment failed', isError: true);
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _stripeLoading = false;
          _stripeError = e.toString();
        });
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.alexandria(fontSize: 13)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_dataLoading) {
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_dataError != null) {
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                _dataError!,
                style: GoogleFonts.alexandria(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _dataError = null;
                    _dataLoading = true;
                  });
                  _loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          _placedOrderNumber = state.orderNumber;
          if (_paymentMethod == PaymentMethod.cashOnDelivery) {
            context.go(
              '${RoutesName.orders}/${RoutesName.confirmedOrders}',
              extra: state.orderNumber,
            );
          } else {
            _handleStripePayment(state.orderNumber);
          }
        } else if (state is OrdersError) {
          _showSnack(state.message);
        }
      },
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(
            'Book Service',
            style:
            GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18),
          ),
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
            constraints:
            BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _StepProgress(step: _step, totalSteps: 5, isDark: isDark),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepTitle,
                          style: GoogleFonts.alexandria(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stepSubtitle,
                          style: GoogleFonts.alexandria(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkSubtext
                                : AppColors.lightSubtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildStep(isDark),
                      ),
                    ),
                  ),
                  _BottomNav(
                    step: _step,
                    totalSteps: 5,
                    enabled: _canProceed,
                    isDark: isDark,
                    isLoading:
                    context.watch<OrdersBloc>().state is OrderPlacing ||
                        _stripeLoading,
                    paymentMethod: _paymentMethod,
                    onBack: () {
                      if (_step == 1) {
                        context.pop();
                      } else if (_step == 2 &&
                          widget.preSelectedServiceId != null) {
                        // Pre-selected from outside — back exits the screen
                        context.pop();
                      } else {
                        setState(() => _step--);
                      }
                    },
                    onNext: () {
                      if (_step < 5)
                        setState(() => _step++);
                      else
                        _placeOrder();
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

  String get _stepTitle => [
    'Select Service',
    'Select Store',
    'Schedule',
    'Address & Notes',
    'Payment',
  ][_step - 1];

  String get _stepSubtitle => [
    'Choose the service that fits your needs',
    'Pick a nearby store location',
    'Set your pickup and delivery times',
    'Enter your address and instructions',
    'Choose how you want to pay',
  ][_step - 1];

  Widget _buildStep(bool isDark) {
    switch (_step) {
      case 1:
        return Column(
          key: const ValueKey(1),
          children: List.generate(
            _services.length,
                (i) => _ServiceCard(
              service: _services[i],
              selected: _serviceIdx == i,
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
              selected: _storeIdx == i,
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
        if (_serviceIdx == null || _storeIdx == null)
          return const SizedBox.shrink();
        return _AddressStep(
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
        return _PaymentStep(
          key: const ValueKey(5),
          selectedMethod: _paymentMethod,
          totalPrice: _serviceIdx != null ? _services[_serviceIdx!].price : 0,
          isDark: isDark,
          stripeError: _stripeError,
          onMethodChanged: (m) => setState(() => _paymentMethod = m),
        );
    }
  }
}

// ─── Step progress ────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int step, totalSteps;
  final bool isDark;

  const _StepProgress({
    required this.step,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isEven) {
          final s = i ~/ 2 + 1;
          final done = s < step;
          final active = s == step;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: (done || active) ? AppColors.gradient : null,
              color: (done || active)
                  ? null
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                '$s',
                style: GoogleFonts.alexandria(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }
        final done = (i ~/ 2 + 1) < step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: done ? AppColors.gradient : null,
              color: done
                  ? null
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    ),
  );
}

// ─── Shared image widget ──────────────────────────────────────────────────────

class _ItemImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool selected;
  final bool isDark;

  const _ItemImage({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? null
        : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9));

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: selected && imageUrl == null ? AppColors.gradient : null,
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: imageUrl != null
            ? CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: isDark
                ? Colors.grey.shade800
                : const Color(0xFFF1F5F9),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: selected ? AppColors.gradient : null,
              color: selected ? null : bg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              fallbackIcon,
              color: selected
                  ? Colors.white
                  : (isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade500),
              size: 24,
            ),
          ),
        )
            : Icon(
          fallbackIcon,
          color: selected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
          size: 24,
        ),
      ),
    );
  }
}

// ─── Service card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceItem service;
  final bool selected, isDark;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    switch (service.category) {
      case 'Dry Clean':
        return Iconsax.wind;
      case 'Iron & Press':
        return Iconsax.flash_1;
      case 'Express':
        return Iconsax.timer_1;
      case 'Steam Clean':
        return Iconsax.cloud;
      case 'Suit Wash':
        return Iconsax.brush_2;
      default:
        return Iconsax.drop;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected
            ? (isDark
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.07))
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : (isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ]),
      ),
      child: Row(
        children: [
          _ItemImage(
            imageUrl: service.imageUrl,
            fallbackIcon: _icon,
            selected: selected,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                if (service.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    service.subtitle,
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '৳${service.price.toStringAsFixed(0)}',
                      style: GoogleFonts.alexandria(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.duration,
                        style: GoogleFonts.alexandria(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradient,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
        ],
      ),
    ),
  );
}

// ─── Store card ───────────────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final _StoreItem store;
  final bool selected, isDark;
  final VoidCallback onTap;

  const _StoreCard({
    required this.store,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected
            ? (isDark
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.07))
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : (isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ]),
      ),
      child: Row(
        children: [
          _ItemImage(
            imageUrl: store.logoUrl,
            fallbackIcon: Iconsax.shop,
            selected: selected,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: GoogleFonts.alexandria(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  store.address,
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.distance,
                        style: GoogleFonts.alexandria(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradient,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
        ],
      ),
    ),
  );
}

// ─── Payment Step ─────────────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final double totalPrice;
  final bool isDark;
  final String? stripeError;
  final ValueChanged<PaymentMethod> onMethodChanged;

  const _PaymentStep({
    super.key,
    required this.selectedMethod,
    required this.totalPrice,
    required this.isDark,
    this.stripeError,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Total Amount',
                style:
                GoogleFonts.alexandria(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '৳${totalPrice.toStringAsFixed(0)}',
                style: GoogleFonts.alexandria(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select your payment method below',
                style: GoogleFonts.alexandria(
                    color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Payment Method',
          style: GoogleFonts.alexandria(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 14),
        _PaymentOption(
          method: PaymentMethod.cashOnDelivery,
          selected: selectedMethod == PaymentMethod.cashOnDelivery,
          isDark: isDark,
          icon: Iconsax.money_recive,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your laundry is delivered',
          badge: null,
          color: AppColors.success,
          onTap: () => onMethodChanged(PaymentMethod.cashOnDelivery),
        ),
        const SizedBox(height: 14),
        _PaymentOption(
          method: PaymentMethod.stripe,
          selected: selectedMethod == PaymentMethod.stripe,
          isDark: isDark,
          icon: Iconsax.card,
          title: 'Pay with Card',
          subtitle: 'Secure payment via Stripe',
          badge: 'Recommended',
          color: const Color(0xFF6772E5),
          onTap: () => onMethodChanged(PaymentMethod.stripe),
        ),
        if (stripeError != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stripeError!,
                    style: GoogleFonts.alexandria(
                        color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedMethod == PaymentMethod.stripe
                      ? 'Your card details are processed securely by Stripe. EzeeWash never stores your card information.'
                      : 'Pay cash to the rider when your clean laundry is delivered to your door.',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final bool selected, isDark;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected
            ? color.withOpacity(0.08)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? color
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.12)
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected
                  ? color
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.alexandria(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.lightText,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.alexandria(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(
                color: selected
                    ? color
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ],
      ),
    ),
  );
}

// ─── Address step ─────────────────────────────────────────────────────────────

class _AddressStep extends StatelessWidget {
  final TextEditingController addrCtrl, noteCtrl;
  final _ServiceItem service;
  final _StoreItem store;
  final DateTime pickupDate, deliveryDate;
  final String pickupTime, deliveryTime;
  final bool isDark;
  final VoidCallback onChanged;

  const _AddressStep({
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
      fontSize: 13,
    ),
    prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
    filled: true,
    fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: isDark
              ? []
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pickup / Delivery Address',
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              maxLines: 2,
              onChanged: (_) => onChanged(),
              decoration: _deco(
                'Enter your complete address',
                Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Special Instructions',
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: _deco(
                'Any special care instructions…',
                Icons.note_alt_outlined,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.primary.withOpacity(0.01),
            ],
          ),
          color: isDark ? const Color(0xFF1A1A2E) : null,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Row('Service', service.title, isDark),
            const SizedBox(height: 8),
            _Row('Store', store.name, isDark),
            const SizedBox(height: 8),
            _Row('Pickup', '${_fmt(pickupDate)} at $pickupTime', isDark),
            const SizedBox(height: 8),
            _Row('Delivery', '${_fmt(deliveryDate)} at $deliveryTime', isDark),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                color:
                isDark ? Colors.white24 : AppColors.primary.withOpacity(0.2),
                thickness: 1.5,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),
                Text(
                  '৳${service.price.toStringAsFixed(0)}',
                  style: GoogleFonts.alexandria(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}

class _Row extends StatelessWidget {
  final String l, v;
  final bool isDark;

  const _Row(this.l, this.v, this.isDark);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: GoogleFonts.alexandria(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          fontSize: 13,
        ),
      ),
      Flexible(
        child: Text(
          v,
          style: GoogleFonts.alexandria(
            color: isDark ? Colors.white : AppColors.lightText,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );
}

// ─── Schedule step ────────────────────────────────────────────────────────────

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

  InputDecoration _deco(String label, Color accent, bool isDark) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ScheduleCard(
        title: 'Pickup Schedule',
        icon: Iconsax.arrow_up_3,
        gradient: AppColors.gradient,
        accent: AppColors.primary,
        date: pickupDate,
        time: pickupTime,
        times: _times,
        isDark: isDark,
        fmt: _fmt,
        deco: _deco,
        onDate: onPickupDate,
        onTime: onPickupTime,
      ),
      const SizedBox(height: 18),
      _ScheduleCard(
        title: 'Delivery Schedule',
        icon: Iconsax.arrow_down_2,
        gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF059669)]),
        accent: AppColors.success,
        date: deliveryDate,
        time: deliveryTime,
        times: _times,
        isDark: isDark,
        fmt: _fmt,
        deco: _deco,
        onDate: onDeliveryDate,
        onTime: onDeliveryTime,
      ),
    ],
  );
}

class _ScheduleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Color accent;
  final DateTime? date;
  final String time;
  final List<String> times;
  final bool isDark;
  final String Function(DateTime?) fmt;
  final InputDecoration Function(String, Color, bool) deco;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTime;

  const _ScheduleCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.date,
    required this.time,
    required this.times,
    required this.isDark,
    required this.fmt,
    required this.deco,
    required this.onDate,
    required this.onTime,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      boxShadow: isDark
          ? []
          : [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.alexandria(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: TextEditingController(text: fmt(date)),
          decoration: deco('Date', accent, isDark).copyWith(
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today_rounded,
                  color: accent, size: 20),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.light(primary: accent),
                    ),
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
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
          decoration: deco('Time', accent, isDark),
          items: times
              .map(
                (t) => DropdownMenuItem(
              value: t,
              child:
              Text(t, style: GoogleFonts.alexandria(fontSize: 14)),
            ),
          )
              .toList(),
          onChanged: (v) {
            if (v != null) onTime(v);
          },
        ),
      ],
    ),
  );
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int step, totalSteps;
  final bool enabled, isDark, isLoading;
  final PaymentMethod paymentMethod;
  final VoidCallback onBack, onNext;

  const _BottomNav({
    required this.step,
    required this.totalSteps,
    required this.enabled,
    required this.isDark,
    required this.isLoading,
    required this.paymentMethod,
    required this.onBack,
    required this.onNext,
  });

  String get _nextLabel {
    if (step < totalSteps) return 'Next';
    return paymentMethod == PaymentMethod.stripe ? 'Pay Now' : 'Confirm Booking';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 14, bottom: 28),
    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              step == 1 ? 'Cancel' : 'Back',
              style: GoogleFonts.alexandria(
                color: isDark ? Colors.white70 : AppColors.lightSubtext,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                _nextLabel,
                style: GoogleFonts.alexandria(
                  color: enabled
                      ? Colors.white
                      : (isDark
                      ? Colors.grey.shade500
                      : Colors.grey.shade400),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}