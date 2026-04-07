// lib/features/orders/presentation/screens/place_order_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/business_utils_logic.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../models/reorder_params.dart';

// ─── Local DB models ──────────────────────────────────────────────────────────

class _ServiceItem {
  final String id, title, subtitle, duration, category;
  final double price;
  final String? imageUrl;

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
  final String? logoUrl;

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
  final String? preSelectedServiceId;
  final ReorderParams? reorderParams;

  const PlaceOrderScreen({
    super.key,
    this.preSelectedServiceId,
    this.reorderParams,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

const double _kServiceCharge = 30.0;
const double _kStripeMinAmount = 100.0;

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  bool _dataLoading = true;
  String? _dataError;
  List<_ServiceItem> _services = [];
  List<_StoreItem> _stores = [];

  int _step = 1;
  int? _serviceIdx;
  int? _storeIdx;
  int _quantity = 1;

  late DateTime _pickupDate;
  late String _pickupTime;
  late DateTime _deliveryDate;
  late String _deliveryTime;

  final _addrCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;

  bool _stripeLoading = false;
  String? _stripeError;
  bool _isCheckingAvailability = false;

  List<String> _pickupTimeSlots = [];
  List<String> _deliveryTimeSlots = [];

  late final PageController _pageController;

  double get _perPcsPrice {
    final rp = widget.reorderParams;
    if (rp != null) return (rp.totalPrice - _kServiceCharge) / rp.itemCount;
    return _serviceIdx != null ? _services[_serviceIdx!].price : 0.0;
  }

  double get _subtotal => _perPcsPrice * _quantity;

  double get _totalPrice => _subtotal + _kServiceCharge;

  bool get _cardAvailable => _totalPrice >= _kStripeMinAmount;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.reorderParams != null ? 4 : 0);

    final rp = widget.reorderParams;
    if (rp != null) {
      _quantity = rp.itemCount;
      _pickupDate = BusinessLogicUtils.clampToMinPickupDate(rp.pickupDate);
      _pickupTime = rp.pickupTime;
      _deliveryDate = BusinessLogicUtils.clampToMinPickupDate(rp.deliveryDate);
      _deliveryTime = rp.deliveryTime;
      _addrCtrl.text = rp.pickupAddress;
      _noteCtrl.text = rp.specialInstructions ?? '';
      _paymentMethod = rp.paymentMethod == 'stripe'
          ? PaymentMethod.stripe
          : PaymentMethod.cashOnDelivery;
      _step = 5;
      _dataLoading = false;
      _refreshTimeSlots();
    } else {
      _pickupDate = BusinessLogicUtils.getMinPickupDate();
      _pickupTime = 'Select time';
      _deliveryDate = _pickupDate;
      _deliveryTime = 'Select time';
      _loadData();
    }
    _addrCtrl.addListener(() => setState(() {}));
  }

  // ─── GETTERS ───

  bool get _isExpress =>
      _serviceIdx != null && _services[_serviceIdx!].category == 'Express';

  List<String> get _categories =>
      _serviceIdx != null ? [_services[_serviceIdx!].category] : const [];

  String get _serviceName =>
      _serviceIdx != null ? _services[_serviceIdx!].title : '';

  bool get _canProceed {
    if (_isCheckingAvailability) return false;
    switch (_step) {
      case 1:
        return _serviceIdx != null;
      case 2:
        return _storeIdx != null;
      case 3:
        return _pickupTime != 'Select time' &&
            _deliveryTime != 'Select time' &&
            _pickupTimeSlots.isNotEmpty &&
            _deliveryTimeSlots.isNotEmpty;
      case 4:
        return _addrCtrl.text.trim().isNotEmpty;
      case 5:
        return true;
      default:
        return false;
    }
  }

  // ─── LOGIC ───

  bool _isClosedDay(DateTime date) => BusinessLogicUtils.isClosedDay(date);

  DateTime get _minPickupDate => BusinessLogicUtils.getMinPickupDate();

  DateTime get _maxPickupDate => BusinessLogicUtils.getMaxPickupDate();

  Future<bool> _checkSlotAvailability() async {
    if (_pickupTime == 'Select time' || _storeIdx == null) return true;

    if (!BusinessLogicUtils.isSubmissionStillValid(_pickupDate, _pickupTime)) {
      AppSnackBar.show(
        context,
        'Selected pickup time window has passed. Please choose a later slot.',
        isError: true,
      );
      return false;
    }

    setState(() => _isCheckingAvailability = true);
    final available = await BusinessLogicUtils.isSlotAvailable(
      _stores[_storeIdx!].id,
      _pickupDate,
      _pickupTime,
      orderValue: _totalPrice,
      orderItemCount: _quantity,
    );
    if (mounted) setState(() => _isCheckingAvailability = false);

    if (!available) {
      AppSnackBar.show(
        context,
        'This slot is fully booked. Please pick another time.',
        isError: true,
      );
    }
    return available;
  }

  Future<void> _refreshTimeSlots() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    setState(() => _isCheckingAvailability = true);

    List<String> slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
      storeId,
      _pickupDate,
      isPickup: true,
      categories: _categories,
    );

    while (slots.isEmpty) {
      _pickupDate = BusinessLogicUtils.getNextBusinessDay(_pickupDate);
      slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
        storeId,
        _pickupDate,
        isPickup: true,
        categories: _categories,
      );
    }

    setState(() {
      _pickupTimeSlots = slots;
      _pickupTime = _pickupTimeSlots.isNotEmpty ? _pickupTimeSlots.first : 'Select time';
      _isCheckingAvailability = false;
    });

    await _syncDelivery();
  }

  Future<void> _syncDelivery() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    final minRequired = BusinessLogicUtils.getMinDeliveryDate(
      _pickupDate,
      _pickupTime,
      _serviceName,
      categories: _categories,
      totalItems: _quantity,
    );

    if (_deliveryDate.isBefore(minRequired)) {
      _deliveryDate = minRequired;
    }

    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      storeId,
      _deliveryDate,
      pickupDate: _pickupDate,
      pickupTime: _pickupTime,
      serviceName: _serviceName,
      categories: _categories,
      totalItems: _quantity,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        storeId,
        _deliveryDate,
        pickupDate: _pickupDate,
        pickupTime: _pickupTime,
        serviceName: _serviceName,
        categories: _categories,
        totalItems: _quantity,
      );
    }

    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty ? _deliveryTimeSlots.first : 'Select time';
    });
  }

  Future<void> _handlePickupDateChanged(DateTime date) async {
    _pickupDate = date;
    await _refreshTimeSlots();
  }

  Future<void> _handlePickupTimeChanged(String time) async {
    _pickupTime = time;
    await _syncDelivery();
  }

  Future<void> _handleDeliveryDateChanged(DateTime date) async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    setState(() => _isCheckingAvailability = true);
    _deliveryDate = date;

    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      storeId,
      _deliveryDate,
      pickupDate: _pickupDate,
      pickupTime: _pickupTime,
      serviceName: _serviceName,
      categories: _categories,
      totalItems: _quantity,
    );

    if (slots.isEmpty) {
      while (slots.isEmpty) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
        while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
          _deliveryDate = _deliveryDate.add(const Duration(days: 1));
        }
        slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
          storeId,
          _deliveryDate,
          pickupDate: _pickupDate,
          pickupTime: _pickupTime,
          serviceName: _serviceName,
          categories: _categories,
          totalItems: _quantity,
        );
      }
    }

    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty ? _deliveryTimeSlots.first : 'Select time';
      _isCheckingAvailability = false;
    });
  }

  // ─── NAV ───

  void _moveToStep(int targetStep) {
    setState(() => _step = targetStep);
    _pageController.animateToPage(
      targetStep - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onConfirm() {
    if (widget.reorderParams == null &&
        (_serviceIdx == null || _storeIdx == null)) {
      return;
    }
    if (_paymentMethod == PaymentMethod.cashOnDelivery) {
      context.read<OrdersBloc>().add(
        OrderPlaceRequested(
            _buildParams(method: PaymentMethod.cashOnDelivery)),
      );
    } else {
      _handleStripePayment();
    }
  }

  PlaceOrderParams _buildParams({required PaymentMethod method}) {
    final rp = widget.reorderParams;
    return PlaceOrderParams(
      serviceId: rp?.serviceId ?? _services[_serviceIdx!].id,
      storeId: rp?.storeId ?? _stores[_storeIdx!].id,
      itemCount: _quantity,
      totalPrice: _totalPrice,
      pickupAddress: _addrCtrl.text.trim(),
      deliveryAddress: _addrCtrl.text.trim(),
      pickupDate: _pickupDate,
      pickupTime: _pickupTime == 'Select time' ? null : _pickupTime,
      deliveryDate: _deliveryDate,
      deliveryTime: _deliveryTime == 'Select time' ? null : _deliveryTime,
      specialInstructions: _noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim(),
      paymentMethod: method,
    );
  }

  Future<void> _handleStripePayment() async {
    if (!mounted) return;
    setState(() {
      _stripeLoading = true;
      _stripeError = null;
    });
    try {
      final svcTitle =
          widget.reorderParams?.serviceName ?? (_serviceIdx != null ? _services[_serviceIdx!].title : '');
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': _totalPrice,
          'currency': 'bdt',
          'orderId': 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
          'description': 'EzeeWash - $svcTitle',
        },
      );
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
            shapes: const PaymentSheetShape(borderRadius: 12),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      if (mounted) {
        context.read<OrdersBloc>().add(
          OrderPlaceRequested(_buildParams(method: PaymentMethod.stripe)),
        );
      }
    } on StripeException catch (e) {
      if (mounted) setState(() => _stripeLoading = false);
      if (e.error.code != FailureCode.Canceled) {
        if (mounted) {
          setState(() {
            _stripeError = e.error.localizedMessage;
          });
          AppSnackBar.show(
            context,
            e.error.localizedMessage ?? 'Payment failed',
            isError: true,
          );
          context.read<OrdersBloc>().add(
            OrderPlaceRequested(_buildParams(method: PaymentMethod.stripe)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stripeLoading = false;
          _stripeError = e.toString();
        });
        AppSnackBar.show(
          context,
          'Payment setup failed. Please try again.',
          isError: true,
        );
        context.read<OrdersBloc>().add(
          OrderPlaceRequested(_buildParams(method: PaymentMethod.stripe)),
        );
      }
    }
  }

  // ─── Boilerplate & UI ─────────────────────────────────────────────────────

  @override
  void dispose() {
    _addrCtrl.dispose();
    _noteCtrl.dispose();
    _pageController.dispose();
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
        final services = (svcs as List)
            .map((e) => _ServiceItem.fromJson(e))
            .toList();
        final stores = (strs as List)
            .map((e) => _StoreItem.fromJson(e))
            .toList();
        int? preIdx;
        if (widget.preSelectedServiceId != null) {
          final idx = services.indexWhere(
                (s) => s.id == widget.preSelectedServiceId,
          );
          if (idx != -1) preIdx = idx;
        }
        setState(() {
          _services = services;
          _stores = stores;
          _serviceIdx = preIdx;
          _dataLoading = false;
        });

        // Fixed logic: If nav from home/service screen, we force a store reset
        // and immediately jump to step 2.
        if (preIdx != null) {
          _storeIdx = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _moveToStep(2);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dataError = e.toString();
          _dataLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_dataLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          context.go(
            '${RoutesName.orders}/${RoutesName.confirmedOrders}',
            extra: state.orderNumber,
          );
        } else if (state is OrdersError) {
          setState(() => _stripeLoading = false);
          AppSnackBar.show(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: const GradientAppBar(title: 'Book Service'),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _StepProgress(
                    step: _step,
                    totalSteps: 5,
                    isDark: isDark,
                    pageController: _pageController,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 48,
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStepForPage(1, isDark),
                        _buildStepForPage(2, isDark),
                        _buildStepForPage(3, isDark),
                        _buildStepForPage(4, isDark),
                        _buildStepForPage(5, isDark),
                      ],
                    ),
                  ),
                  _BottomNav(
                    step: _step,
                    totalSteps: 5,
                    enabled: _canProceed,
                    isDark: isDark,
                    isLoading:
                    (context.watch<OrdersBloc>().state is OrderPlacing) ||
                        _stripeLoading ||
                        _isCheckingAvailability,
                    paymentMethod: _paymentMethod,
                    onBack: () {
                      if (_step == 1) {
                        context.pop();
                      } else if (_step == 5 && widget.reorderParams != null) {
                        context.pop();
                      } else {
                        _moveToStep(_step - 1);
                      }
                    },
                    onNext: () async {
                      if (_step == 3) {
                        bool available = await _checkSlotAvailability();
                        if (!available) return;
                      }
                      if (_step == 2) await _refreshTimeSlots();
                      if (_step < 5) {
                        _moveToStep(_step + 1);
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

  String get _stepTitle {
    return [
      'Select Service',
      'Select Store',
      'Schedule',
      'Address Selection',
      'Payment',
    ][_step - 1];
  }

  Widget _buildStepForPage(int stepNum, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: _buildStep(stepNum, isDark),
    );
  }

  Widget _buildStep(int stepNum, bool isDark) {
    switch (stepNum) {
      case 1:
        return Column(
          children: List.generate(
            _services.length,
                (i) => _ServiceCard(
              service: _services[i],
              selected: _serviceIdx == i,
              isDark: isDark,
              onTap: () => setState(() {
                _serviceIdx = i;
                // Resets store selection if service is manually changed in step 1
                _storeIdx = null;
              }),
            ),
          ),
        );
      case 2:
        return Column(
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
          minPickupDate: _minPickupDate,
          maxPickupDate: _maxPickupDate,
          pickupDate: _pickupDate,
          pickupTime: _pickupTime,
          deliveryDate: _deliveryDate,
          deliveryTime: _deliveryTime,
          isDark: isDark,
          isExpress: _isExpress,
          pickupTimeSlots: _pickupTimeSlots,
          deliveryTimeSlots: _deliveryTimeSlots,
          onPickupDate: _handlePickupDateChanged,
          onPickupTime: _handlePickupTimeChanged,
          onDeliveryDate: _handleDeliveryDateChanged,
          onDeliveryTime: (t) => setState(() => _deliveryTime = t),
          minDeliveryDate: BusinessLogicUtils.getMinDeliveryDate(
            _pickupDate,
            _pickupTime,
            _serviceName,
            categories: _categories,
            totalItems: _quantity,
          ),
          isClosedDay: _isClosedDay,
          processingLabel: BusinessLogicUtils.processingTimeLabel(
            _serviceName,
            categories: _categories,
          ),
          pickupSelectablePredicate: (DateTime val) =>
          !_isClosedDay(val) &&
              BusinessLogicUtils.getAvailableSlots(
                val,
                isPickup: true,
                categories: _categories,
              ).isNotEmpty,
          deliverySelectablePredicate: (DateTime val) =>
          !_isClosedDay(val) &&
              BusinessLogicUtils.getDeliverySlots(
                val,
                pickupDate: _pickupDate,
                pickupTime: _pickupTime,
                serviceName: _serviceName,
                categories: _categories,
                totalItems: _quantity,
              ).isNotEmpty,
        );
      case 4:
        return _AddressStep(
          addrCtrl: _addrCtrl,
          noteCtrl: _noteCtrl,
          isDark: isDark,
          onChanged: () => setState(() {}),
        );
      default:
        final rp = widget.reorderParams;
        return _PaymentStep(
          selectedMethod: _paymentMethod,
          perPcsPrice: _perPcsPrice,
          quantity: _quantity,
          subtotal: _subtotal,
          serviceCharge: _kServiceCharge,
          totalPrice: _totalPrice,
          cardAvailable: _cardAvailable,
          isDark: isDark,
          stripeError: _stripeError,
          serviceName: rp?.serviceName ?? (_serviceIdx != null ? _services[_serviceIdx!].title : ''),
          storeName: rp?.storeName ?? (_storeIdx != null ? _stores[_storeIdx!].name : ''),
          pickupInfo: '${_fmtDate(_pickupDate)} at $_pickupTime',
          deliveryInfo: '${_fmtDate(_deliveryDate)} at $_deliveryTime',
          onMethodChanged: (m) => setState(() => _paymentMethod = m),
          onQuantityChanged: (q) => setState(() {
            _quantity = q;
            if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
          }),
        );
    }
  }

  String _fmtDate(DateTime d) => BusinessLogicUtils.formatDate(d);
}

// ─── Schedule Step Component ──────────────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  final DateTime pickupDate, deliveryDate;
  final DateTime minDeliveryDate;
  final DateTime minPickupDate;
  final DateTime maxPickupDate;
  final String pickupTime, deliveryTime;
  final bool isDark, isExpress;
  final List<String> pickupTimeSlots, deliveryTimeSlots;
  final ValueChanged<DateTime> onPickupDate, onDeliveryDate;
  final ValueChanged<String> onPickupTime, onDeliveryTime;
  final bool Function(DateTime) isClosedDay;
  final String processingLabel;
  final bool Function(DateTime) pickupSelectablePredicate;
  final bool Function(DateTime) deliverySelectablePredicate;

  const _ScheduleStep({
    required this.minPickupDate,
    required this.maxPickupDate,
    required this.pickupDate,
    required this.deliveryDate,
    required this.pickupTime,
    required this.deliveryTime,
    required this.isDark,
    required this.isExpress,
    required this.pickupTimeSlots,
    required this.deliveryTimeSlots,
    required this.onPickupDate,
    required this.onDeliveryDate,
    required this.onPickupTime,
    required this.onDeliveryTime,
    required this.minDeliveryDate,
    required this.isClosedDay,
    required this.processingLabel,
    required this.pickupSelectablePredicate,
    required this.deliverySelectablePredicate,
  });

  static String _fmt(DateTime? d) =>
      d == null ? '' : BusinessLogicUtils.formatDate(d);

  static InputDecoration _deco(String label, Color accent, bool isDark) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        labelStyle: GoogleFonts.alexandria(
          fontSize: 12,
          color: accent.withOpacity(0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SchCard(
          title: 'Pickup Schedule',
          icon: Iconsax.arrow_up_3,
          gradient: AppColors.gradient,
          accent: AppColors.primary,
          date: pickupDate,
          time: pickupTime,
          times: pickupTimeSlots,
          isDark: isDark,
          fmt: _fmt,
          deco: _deco,
          onDate: onPickupDate,
          onTime: onPickupTime,
          minDate: minPickupDate,
          maxDate: maxPickupDate,
          selectablePredicate: pickupSelectablePredicate,
          noSlotsMessage: BusinessLogicUtils.noSlotsReason(pickupDate),
        ),
        const SizedBox(height: 12),
        _SchCard(
          title: 'Delivery Schedule',
          icon: Iconsax.arrow_down_2,
          gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF059669)],
          ),
          accent: AppColors.success,
          date: deliveryDate,
          time: deliveryTime,
          times: deliveryTimeSlots,
          isDark: isDark,
          fmt: _fmt,
          deco: _deco,
          onDate: onDeliveryDate,
          onTime: onDeliveryTime,
          minDate: minDeliveryDate,
          maxDate: BusinessLogicUtils.getMaxPickupDate().add(
            Duration(days: BusinessLogicUtils.kStandardHours ~/ 8 + 2),
          ),
          selectablePredicate: deliverySelectablePredicate,
          noSlotsMessage: BusinessLogicUtils.noSlotsReason(deliveryDate),
        ),
      ],
    );
  }
}

class _SchCard extends StatelessWidget {
  final String title, noSlotsMessage;
  final IconData icon;
  final Gradient gradient;
  final Color accent;
  final DateTime? date, minDate, maxDate;
  final String time;
  final List<String> times;
  final bool isDark;
  final String Function(DateTime?) fmt;
  final InputDecoration Function(String, Color, bool) deco;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTime;
  final bool Function(DateTime) selectablePredicate;

  const _SchCard({
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
    required this.noSlotsMessage,
    required this.selectablePredicate,
    this.minDate,
    this.maxDate,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSlots = times.isNotEmpty;
    final String currentDisplayTime = (hasSlots && times.contains(time))
        ? time
        : (hasSlots ? times[0] : 'Select time');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
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
            readOnly: true,
            style: GoogleFonts.alexandria(fontSize: 14),
            decoration: deco('Date', accent, isDark).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.calendar_today_rounded,
                  color: accent,
                  size: 20,
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final firstDate = minDate ?? now;
                  final lastDate =
                      maxDate ?? BusinessLogicUtils.getMaxPickupDate();
                  DateTime initial =
                  (date != null && !date!.isBefore(firstDate))
                      ? date!
                      : firstDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    selectableDayPredicate: selectablePredicate,
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
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: currentDisplayTime == 'Select time'
                ? null
                : currentDisplayTime,
            hint: Text(
              'Select time',
              style: GoogleFonts.alexandria(fontSize: 14, color: Colors.grey),
            ),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
            decoration: deco('Time', accent, isDark),
            items: times
                .map(
                  (t) => DropdownMenuItem(
                value: t,
                child: Text(
                  t,
                  style: GoogleFonts.alexandria(fontSize: 14),
                ),
              ),
            )
                .toList(),
            onChanged: hasSlots
                ? (v) {
              if (v != null) onTime(v);
            }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Remaining Components ─────────────────────────────────────────────────────

class _AddressStep extends StatefulWidget {
  final TextEditingController addrCtrl, noteCtrl;
  final bool isDark;
  final VoidCallback onChanged;

  const _AddressStep({
    required this.addrCtrl,
    required this.noteCtrl,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> {
  GoogleMapController? _mapController;
  LatLng _centerPosition = const LatLng(23.8103, 90.4125);
  bool _isMoving = false;
  bool? _locationPermissionGranted;

  @override
  void initState() {
    super.initState();
    _requestAndLocate();
  }

  Future<void> _requestAndLocate() async {
    LocationPermission status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      setState(() => _locationPermissionGranted = true);
      await _getUserCurrentLocation();
    } else {
      setState(() => _locationPermissionGranted = false);
    }
  }

  Future<void> _getUserCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final target = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
        duration: const Duration(seconds: 1),
      );
      _getAddressFromLatLng(target);
    } catch (_) {}
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        widget.addrCtrl.text = '${p.street}, ${p.subLocality}, ${p.locality}';
        widget.onChanged();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                GoogleMap(
                  gestureRecognizers: {
                    Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                    ),
                  },
                  initialCameraPosition: CameraPosition(
                    target: _centerPosition,
                    zoom: 14,
                  ),
                  myLocationEnabled: _locationPermissionGranted == true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  style: widget.isDark ? AppConstants.darkMapStyle : null,
                  onMapCreated: (c) => _mapController = c,
                  onCameraMoveStarted: () => setState(() => _isMoving = true),
                  onCameraMove: (p) => _centerPosition = p.target,
                  onCameraIdle: () {
                    setState(() => _isMoving = false);
                    _getAddressFromLatLng(_centerPosition);
                  },
                ),
                if (_locationPermissionGranted == false)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xCC1A2540)
                            : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 16,
                            color: widget.isDark
                                ? Colors.white70
                                : AppColors.lightSubtext,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location denied — enable in settings or drag the pin',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.isDark
                                    ? Colors.white70
                                    : AppColors.lightSubtext,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: widget.addrCtrl.text.isEmpty || _isMoving
                        ? const SizedBox.shrink()
                        : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 250),
                      decoration: BoxDecoration(
                        color: widget.isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.addrCtrl.text,
                        style: GoogleFonts.alexandria(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white : AppColors.lightText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(
                        0,
                        _isMoving ? -10 : 0,
                        0,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 45,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: widget.isDark
                        ? AppColors.darkSurface
                        : Colors.white,
                    onPressed: _getUserCurrentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: widget.noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add specific notes...',
            filled: true,
            fillColor: widget.isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Iconsax.note_2),
          ),
          style: GoogleFonts.alexandria(fontSize: 13),
        ),
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final double perPcsPrice, subtotal, serviceCharge, totalPrice;
  final int quantity;
  final bool cardAvailable, isDark;
  final String? stripeError, serviceName, storeName, pickupInfo, deliveryInfo;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final ValueChanged<int> onQuantityChanged;

  const _PaymentStep({
    required this.selectedMethod,
    required this.perPcsPrice,
    required this.quantity,
    required this.subtotal,
    required this.serviceCharge,
    required this.totalPrice,
    required this.cardAvailable,
    required this.isDark,
    this.stripeError,
    this.serviceName,
    this.storeName,
    this.pickupInfo,
    this.deliveryInfo,
    required this.onMethodChanged,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              _SummaryLine('Service', serviceName ?? ''),
              _SummaryLine('Store', storeName ?? ''),
              _SummaryLine('Pickup', pickupInfo ?? ''),
              _SummaryLine('Delivery', deliveryInfo ?? ''),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Divider(
                  color: Colors.white.withOpacity(0.1),
                  thickness: 1,
                ),
              ),
              _SummaryLine(
                '$quantity pcs × ৳${perPcsPrice.toStringAsFixed(0)}',
                '৳${subtotal.toStringAsFixed(0)}',
              ),
              _SummaryLine(
                'Service Charge',
                '৳${serviceCharge.toStringAsFixed(0)}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Divider(
                  color: Colors.white.withOpacity(0.25),
                  thickness: 1,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '৳${totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.alexandria(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number of Pieces',
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳${perPcsPrice.toStringAsFixed(0)} per piece',
                style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QtyBtn(
                    icon: Icons.remove_rounded,
                    enabled: quantity > 1,
                    isDark: isDark,
                    onTap: () => onQuantityChanged(quantity - 1),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$quantity',
                        style: GoogleFonts.alexandria(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add_rounded,
                    enabled: quantity < 99,
                    isDark: isDark,
                    onTap: () => onQuantityChanged(quantity + 1),
                  ),
                ],
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
        _PaymentOpt(
          method: PaymentMethod.cashOnDelivery,
          selected: selectedMethod == PaymentMethod.cashOnDelivery,
          isDark: isDark,
          icon: Iconsax.money_recive,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your laundry is delivered',
          color: AppColors.success,
          onTap: () => onMethodChanged(PaymentMethod.cashOnDelivery),
        ),
        const SizedBox(height: 14),
        if (cardAvailable)
          _PaymentOpt(
            method: PaymentMethod.stripe,
            selected: selectedMethod == PaymentMethod.stripe,
            isDark: isDark,
            icon: Iconsax.card,
            title: 'Pay with Card',
            subtitle: 'Secure payment via Stripe',
            badge: 'Recommended',
            color: const Color(0xFF6772E5),
            onTap: () => onMethodChanged(PaymentMethod.stripe),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(Iconsax.card, color: Colors.grey.shade400, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay with Card',
                        style: GoogleFonts.alexandria(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Requires ৳100 minimum.',
                        style: GoogleFonts.alexandria(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (stripeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              stripeError!,
              style: GoogleFonts.alexandria(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _SummaryLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.alexandria(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

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

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 10, top: 2),
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
          child: Container(
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.gradient : null,
              color: enabled
                  ? null
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                step < totalSteps
                    ? 'Next'
                    : (paymentMethod == PaymentMethod.stripe
                    ? 'Pay Now'
                    : 'Confirm'),
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

class _StepProgress extends StatelessWidget {
  final int step, totalSteps;
  final bool isDark;
  final PageController pageController;

  const _StepProgress({
    required this.step,
    required this.totalSteps,
    required this.isDark,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.darkBorder),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) {
                    double page = pageController.hasClients ? (pageController.page ?? step - 1.0) : (step - 1.0);
                    double progress = page / (totalSteps - 1);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 3,
                        width: constraints.maxWidth * progress.clamp(0, 1),
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (i) {
            final s = i + 1;

            return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double page = pageController.hasClients ? (pageController.page ?? step - 1.0) : (step - 1.0);

                  bool isDone = page > i;
                  bool isActive = page.round() == i;

                  Color circleColor = isDone || isActive ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade100);
                  if (pageController.hasClients) {
                    double distance = (page - i).abs();
                    double t = (1.0 - distance).clamp(0.0, 1.0);
                    circleColor = Color.lerp(
                        isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        AppColors.primary,
                        isDone ? 1.0 : t
                    )!;
                  }

                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                        '$s',
                        style: GoogleFonts.alexandria(
                          color: isDone || isActive ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
            );
          }),
        ),
      ],
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled, isDark;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.gradient : null,
        color: enabled
            ? null
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: enabled ? Colors.white : Colors.grey.shade400,
        size: 22,
      ),
    ),
  );
}

class _PaymentOpt extends StatelessWidget {
  final PaymentMethod method;
  final bool selected, isDark;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOpt({
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
  Widget build(BuildContext context) {
    return GestureDetector(
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
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade50),
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
                            horizontal: 8,
                            vertical: 3,
                          ),
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
}

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        ),
        child: Row(
          children: [
            _ItemImage(
              imageUrl: service.imageUrl,
              fallbackIcon: Iconsax.drop,
              selected: selected,
              isDark: isDark,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                service.title,
                style: GoogleFonts.alexandria(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              if (service.subtitle.isNotEmpty)
                Text(
                  service.subtitle,
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                  maxLines: 1,
                ),
              const SizedBox(height: 10),
              Text(
                '৳${service.price.toStringAsFixed(0)}',
                style: GoogleFonts.alexandria(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
}

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
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  Text(
                    store.distance,
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
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
}

class _ItemImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool selected, isDark;

  const _ItemImage({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: selected && imageUrl == null ? AppColors.gradient : null,
        color: selected
            ? null
            : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: imageUrl != null
            ? CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => Icon(
            fallbackIcon,
            color: selected ? Colors.white : Colors.grey,
          ),
        )
            : Icon(fallbackIcon, color: selected ? Colors.white : Colors.grey),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDark;
  const _ServiceImage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        gradient: imageUrl == null ? AppColors.gradient : null,
        color: imageUrl != null
            ? (isDark ? AppColors.darkSurface : Colors.grey.shade100)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor:
            isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (_, _, _) => Container(
              decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.local_laundry_service,
                  color: Colors.white, size: 28)),
        )
            : const Icon(Icons.local_laundry_service,
            color: Colors.white, size: 28),
      ),
    );
  }
}