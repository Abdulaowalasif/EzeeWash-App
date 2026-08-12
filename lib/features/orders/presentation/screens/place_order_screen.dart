// lib/features/orders/presentation/screens/place_order_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/business_utils_logic.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form/app_step_progress.dart';
import '../../../../core/widgets/form/app_stepper_bottom_nav.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../models/reorder_params.dart';
import '../widgets/place order/po_address_step.dart';
import '../widgets/place order/po_payment_step.dart';
import '../widgets/place order/po_schedule_step.dart';
import '../widgets/place order/po_service_card.dart';
import '../widgets/place order/po_store_card.dart';

const double _kServiceCharge = 30.0;
const double _kStripeMinAmount = 100.0;

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

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  // ─── Data ────────────────────────────────────────────────────────────────────
  bool _dataLoading = true;
  String? _dataError;
  List<PoServiceItem> _services = [];
  List<PoStoreItem> _stores = [];

  // ─── Step / selections ───────────────────────────────────────────────────────
  int _step = 1;
  int? _serviceIdx;
  int? _storeIdx;
  int _quantity = 1;
  String? _selectedComforterSize;

  // ─── Schedule ────────────────────────────────────────────────────────────────
  late DateTime _pickupDate;
  late String _pickupTime;
  late DateTime _deliveryDate;
  late String _deliveryTime;
  List<String> _pickupTimeSlots = [];
  List<String> _deliveryTimeSlots = [];
  bool _isCheckingAvailability = false;

  // ─── Address / payment ───────────────────────────────────────────────────────
  final _addrCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  bool _stripeLoading = false;
  String? _stripeError;

  // ─── Coupon tracking ──────────────────────────────────────────────────────────
  String? _appliedCoupon;
  double _discountAmount = 0.0;
  String? _appliedDiscountType;
  double? _appliedDiscountValue;
  double? _appliedMaxDiscount;
  double? _appliedMinOrderAmount; // Track min requirement for re-validation

  late final PageController _pageController;

  // ─── Computed ────────────────────────────────────────────────────────────────

  double get _perPcsPrice {
    final rp = widget.reorderParams;
    if (rp != null) {
      // ── FIXED: Adding the discount amount back to find the TRUE base price ──
      return (rp.totalPrice - _kServiceCharge + rp.discountAmount) / rp.itemCount;
    }
    return _serviceIdx != null ? _services[_serviceIdx!].price : 0.0;
  }

  double get _subtotal => _perPcsPrice * _quantity;

  double get _totalPrice =>
      (_subtotal + _kServiceCharge - _discountAmount).clamp(0.0, double.infinity);

  bool get _cardAvailable => _totalPrice >= _kStripeMinAmount;

  bool get _isExpress =>
      _serviceIdx != null && _services[_serviceIdx!].category == 'Express';

  List<String> get _categories =>
      _serviceIdx != null ? [_services[_serviceIdx!].category] : const [];

  String get _serviceName =>
      _serviceIdx != null ? _services[_serviceIdx!].title : '';

  bool get _canProceed {
    if (_isCheckingAvailability) return false;
    switch (_step) {
      case 1: return _serviceIdx != null;
      case 2: return _storeIdx != null;
      case 3:
        return _pickupTime != 'Select time' &&
            _deliveryTime != 'Select time' &&
            _pickupTimeSlots.isNotEmpty &&
            _deliveryTimeSlots.isNotEmpty;
      case 4: return _addrCtrl.text.trim().isNotEmpty;
      case 5: return true;
      default: return false;
    }
  }

  String get _stepTitle => const [
    'Select Service',
    'Select Store',
    'Schedule',
    'Address Selection',
    'Payment',
  ][_step - 1];

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.reorderParams != null ? 4 : 0,
    );

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

  @override
  void dispose() {
    _addrCtrl.dispose();
    _noteCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Data loading ─────────────────────────────────────────────────────────────

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

      if (!mounted) return;

      final services =
      (svcs as List).map((e) => PoServiceItem.fromJson(e)).toList();
      final stores =
      (strs as List).map((e) => PoStoreItem.fromJson(e)).toList();

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
      });

      if (preIdx != null) {
        _storeIdx = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => _moveToStep(2));
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

  // ─── Coupon Logic ─────────────────────────────────────────────────────────────

  double _computeDiscount(String type, double value, double? maxDiscount) {
    final orderBeforeDiscount = _subtotal + _kServiceCharge;
    double discount;
    if (type == 'percentage') {
      discount = orderBeforeDiscount * value / 100.0;
      if (maxDiscount != null && discount > maxDiscount) {
        discount = maxDiscount;
      }
    } else {
      discount = value;
    }
    return discount.clamp(0.0, orderBeforeDiscount);
  }

  Future<String?> _validateAndApplyCoupon(String code) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'Please log in to use coupons.';

      final rows = await Supabase.instance.client
          .from('promos')
          .select()
          .ilike('code', code)
          .eq('is_active', true)
          .limit(1);

      if (rows == null || (rows as List).isEmpty) {
        return 'Invalid coupon code.';
      }

      final promo = rows.first as Map<String, dynamic>;

      final previousOrdersWithCoupon = await Supabase.instance.client
          .from(AppConstants.ordersTable)
          .select('id')
          .eq('user_id', userId)
          .ilike('coupon_code', code);

      if (previousOrdersWithCoupon.isNotEmpty) {
        return 'You have already used this coupon.';
      }

      final validFrom = DateTime.parse(promo['valid_from'] as String);
      final validUntil = promo['valid_until'] != null
          ? DateTime.parse(promo['valid_until'] as String)
          : null;
      final nowDt = DateTime.now().toUtc();

      if (nowDt.isBefore(validFrom)) return 'This coupon is not active yet.';
      if (validUntil != null && nowDt.isAfter(validUntil)) {
        return 'This coupon has expired.';
      }

      final usageLimit = promo['usage_limit'] as int?;
      final timesUsed = promo['times_used'] as int? ?? 0;
      if (usageLimit != null && timesUsed >= usageLimit) {
        return 'This coupon has reached its usage limit.';
      }

      final targetUserId = promo['target_user_id'] as String?;
      if (targetUserId != null && targetUserId != userId) {
        return 'This coupon is not valid for your account.';
      }

      final targetServiceId = promo['target_service_id'] as String?;
      if (targetServiceId != null) {
        final currentServiceId = widget.reorderParams?.serviceId ??
            (_serviceIdx != null ? _services[_serviceIdx!].id : null);
        if (currentServiceId != targetServiceId) {
          return 'This coupon does not apply to the selected service.';
        }
      }

      final minOrder = (promo['min_order_amount'] as num?)?.toDouble();
      final orderBeforeDiscount = _subtotal + _kServiceCharge;
      if (minOrder != null && orderBeforeDiscount < minOrder) {
        return 'Minimum order of ৳${minOrder.toStringAsFixed(0)} required.';
      }

      final discountType = promo['discount_type'] as String;
      final discountValue = (promo['discount_value'] as num).toDouble();
      final maxDiscount = (promo['max_discount_amount'] as num?)?.toDouble();

      setState(() {
        _appliedCoupon = (promo['code'] as String).toUpperCase();
        _appliedMinOrderAmount = minOrder;
        _appliedDiscountType = discountType;
        _appliedDiscountValue = discountValue;
        _appliedMaxDiscount = maxDiscount;
        _discountAmount = _computeDiscount(discountType, discountValue, maxDiscount);

        if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
      });

      return null;
    } catch (e) {
      return 'Could not validate coupon. Please try again.';
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _appliedDiscountType = null;
      _appliedDiscountValue = null;
      _appliedMaxDiscount = null;
      _appliedMinOrderAmount = null;
    });
  }

  // ─── Schedule helpers ─────────────────────────────────────────────────────────

  Future<void> _refreshTimeSlots() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    setState(() => _isCheckingAvailability = true);

    List<String> slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
      storeId, _pickupDate, isPickup: true, categories: _categories,
    );

    while (slots.isEmpty) {
      _pickupDate = BusinessLogicUtils.getNextBusinessDay(_pickupDate);
      slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
        storeId, _pickupDate, isPickup: true, categories: _categories,
      );
    }

    setState(() {
      _pickupTimeSlots = slots;
      _pickupTime =
      _pickupTimeSlots.isNotEmpty ? _pickupTimeSlots.first : 'Select time';
      _isCheckingAvailability = false;
    });

    await _syncDelivery();
  }

  Future<void> _syncDelivery() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    final minRequired = BusinessLogicUtils.getMinDeliveryDate(
      _pickupDate, _pickupTime, _serviceName,
      categories: _categories, totalItems: _quantity,
    );
    if (_deliveryDate.isBefore(minRequired)) _deliveryDate = minRequired;

    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      storeId, _deliveryDate,
      pickupDate: _pickupDate, pickupTime: _pickupTime,
      serviceName: _serviceName, categories: _categories, totalItems: _quantity,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        storeId, _deliveryDate,
        pickupDate: _pickupDate, pickupTime: _pickupTime,
        serviceName: _serviceName, categories: _categories, totalItems: _quantity,
      );
    }

    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty
          ? _deliveryTimeSlots.first
          : 'Select time';
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
      storeId, _deliveryDate,
      pickupDate: _pickupDate, pickupTime: _pickupTime,
      serviceName: _serviceName, categories: _categories, totalItems: _quantity,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        storeId, _deliveryDate,
        pickupDate: _pickupDate, pickupTime: _pickupTime,
        serviceName: _serviceName, categories: _categories, totalItems: _quantity,
      );
    }

    setState(() {
      _deliveryTimeSlots = slots;
      _deliveryTime = _deliveryTimeSlots.isNotEmpty
          ? _deliveryTimeSlots.first
          : 'Select time';
      _isCheckingAvailability = false;
    });
  }

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
      _stores[_storeIdx!].id, _pickupDate, _pickupTime,
      orderValue: _totalPrice, orderItemCount: _quantity,
    );
    if (mounted) setState(() => _isCheckingAvailability = false);

    if (!available) {
      AppSnackBar.show(
        context, 'This slot is fully booked. Please pick another time.',
        isError: true,
      );
    }
    return available;
  }

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
      specialInstructions: _buildSpecialInstructions(),
      paymentMethod: method,
      couponCode: _appliedCoupon,
      discountAmount: _discountAmount,
    );
  }

  String? _buildSpecialInstructions() {
    final note = _noteCtrl.text.trim();
    if (_selectedComforterSize != null) {
      if (note.isEmpty) return 'Size: $_selectedComforterSize';
      return 'Size: $_selectedComforterSize\n$note';
    }
    return note.isEmpty ? null : note;
  }

  Future<void> _handleStripePayment() async {
    if (!mounted) return;
    setState(() {
      _stripeLoading = true;
      _stripeError = null;
    });
    try {
      final svcTitle = widget.reorderParams?.serviceName ??
          (_serviceIdx != null ? _services[_serviceIdx!].title : '');
      final response = await Supabase.instance.client.functions.invoke(
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
      if (e.error.code != FailureCode.Canceled && mounted) {
        setState(() => _stripeError = e.error.localizedMessage);
        AppSnackBar.show(
          context, e.error.localizedMessage ?? 'Payment failed', isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stripeLoading = false;
          _stripeError = e.toString();
        });
        AppSnackBar.show(
          context, 'Payment setup failed. Please try again.', isError: true,
        );
      }
    }
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

    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrderPlaced) {
          context.read<OrdersBloc>().add(const OrdersLoadRequested());
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
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                  AppStepProgress(step: _step, totalSteps: 5, isDark: isDark),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 48,
                      child: Text(
                        _stepTitle,
                        style: AppTextStyles.heading(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        5,
                            (i) => SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildStep(i + 1, isDark),
                        ),
                      ),
                    ),
                  ),
                  AppStepperBottomNav(
                    step: _step,
                    totalSteps: 5,
                    enabled: _canProceed,
                    isDark: isDark,
                    isLoading:
                    (context.watch<OrdersBloc>().state is OrderPlacing) ||
                        _stripeLoading ||
                        _isCheckingAvailability,
                    confirmLabel: _paymentMethod == PaymentMethod.stripe
                        ? 'Pay Now'
                        : 'Confirm',
                    onBack: () {
                      if (_step == 1 ||
                          (_step == 5 && widget.reorderParams != null)) {
                        context.pop();
                      } else {
                        _moveToStep(_step - 1);
                      }
                    },
                    onNext: () async {
                      if (_step == 3) {
                        final ok = await _checkSlotAvailability();
                        if (!ok) return;
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

  Widget _buildStep(int stepNum, bool isDark) {
    switch (stepNum) {
      case 1:
        return Column(
          children: List.generate(_services.length, (i) {
            return PoServiceCard(
              service: _services[i],
              selected: _serviceIdx == i,
              isDark: isDark,
              onTap: () => setState(() {
                _serviceIdx = i;
                _storeIdx = null;
              }),
            );
          }),
        );

      case 2:
        return Column(
          children: List.generate(_stores.length, (i) {
            return PoStoreCard(
              store: _stores[i],
              selected: _storeIdx == i,
              isDark: isDark,
              onTap: () => setState(() => _storeIdx = i),
            );
          }),
        );

      case 3:
        return PoScheduleStep(
          minPickupDate: BusinessLogicUtils.getMinPickupDate(),
          maxPickupDate: BusinessLogicUtils.getMaxPickupDate(),
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
            _pickupDate, _pickupTime, _serviceName,
            categories: _categories, totalItems: _quantity,
          ),
          isClosedDay: BusinessLogicUtils.isClosedDay,
          processingLabel: BusinessLogicUtils.processingTimeLabel(
            _serviceName, categories: _categories,
          ),
        );

      case 4:
        return PoAddressStep(
          addrCtrl: _addrCtrl,
          noteCtrl: _noteCtrl,
          isDark: isDark,
          onChanged: () => setState(() {}),
        );

      default:
        final rp = widget.reorderParams;
        return PoPaymentStep(
          selectedMethod: _paymentMethod,
          perPcsPrice: _perPcsPrice,
          quantity: _quantity,
          subtotal: _subtotal,
          serviceCharge: _kServiceCharge,
          totalPrice: _totalPrice,
          discountAmount: _discountAmount,
          cardAvailable: _cardAvailable,
          isDark: isDark,
          stripeError: _stripeError,
          appliedCoupon: _appliedCoupon,
          selectedSize: _selectedComforterSize,
          onSizeChanged: (s) => setState(() => _selectedComforterSize = s),
          serviceName: rp?.serviceName ??
              (_serviceIdx != null ? _services[_serviceIdx!].title : ''),
          storeName: rp?.storeName ??
              (_storeIdx != null ? _stores[_storeIdx!].name : ''),
          pickupInfo:
          '${BusinessLogicUtils.formatDate(_pickupDate)} at $_pickupTime',
          deliveryInfo:
          '${BusinessLogicUtils.formatDate(_deliveryDate)} at $_deliveryTime',
          onMethodChanged: (m) => setState(() => _paymentMethod = m),
          onQuantityChanged: (q) => setState(() {
            _quantity = q;

            if (_appliedCoupon != null && _appliedMinOrderAmount != null) {
              if ((_subtotal + _kServiceCharge) < _appliedMinOrderAmount!) {
                _removeCoupon();
                AppSnackBar.show(
                  context,
                  'Coupon removed: Minimum order of ৳${_appliedMinOrderAmount!.toStringAsFixed(0)} required.',
                  isError: true,
                );
              }
            }

            if (_appliedDiscountType != null && _appliedDiscountValue != null) {
              _discountAmount = _computeDiscount(
                _appliedDiscountType!,
                _appliedDiscountValue!,
                _appliedMaxDiscount,
              );
            }
            if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
          }),
          onApplyCoupon: _validateAndApplyCoupon,
          onRemoveCoupon: _removeCoupon,
        );
    }
  }
}