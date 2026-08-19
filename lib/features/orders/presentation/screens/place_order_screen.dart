// lib/features/orders/presentation/screens/place_order_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/business_utils_logic.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/di/injection_container.dart';
import '../../../services/data/datasources/service_remote_datasource.dart';
import '../../../store/data/datasources/stores_remote_datasouce.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form/app_step_progress.dart';
import '../../../../core/widgets/form/app_stepper_bottom_nav.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../../../routes/routes_name.dart';
import '../../../profile/domain/entities/address_entity.dart';
import '../../../services/data/models/service_model.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../store/data/models/store_model.dart';
import '../../../store/domain/entities/store_entity.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../models/reorder_params.dart';
import '../widgets/place_order/po_address_step.dart';
import '../widgets/place_order/po_confirmation_step.dart';
import '../widgets/place_order/po_payment_method_step.dart';
import '../widgets/place_order/po_schedule_step.dart';
import '../widgets/place_order/po_service_card.dart';
import '../widgets/place_order/po_store_card.dart';

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
  List<ServiceEntity> _services = [];
  List<StoreEntity> _stores = [];

  // ─── Step / selections ───────────────────────────────────────────────────────
  int _step = 1;
  Set<int> _selectedServiceIndices = {};
  int? _storeIdx;
  Map<int, int> _serviceQuantities = {};
  Map<int, Map<String, int>> _comforterQuantities = {};

  // ─── Submission Tracking ─────────────────────────────────────────────────────
  int _ordersToPlace = 0;
  int _ordersPlacedSuccessfully = 0;
  int _reorderQuantity = 1;

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
  String? _couponTargetServiceId;
  
  late final PageController _pageController;
  Completer<String?>? _couponCompleter;

  // ─── Computed ────────────────────────────────────────────────────────────────

  double get _kServiceCharge {
    if (widget.reorderParams != null) return 30.0;
    final int count = _selectedServiceIndices.length;
    if (count <= 1) return 30.0;
    
    double charge = 30.0;
    if (count >= 2) charge += 20.0;
    if (count >= 3) charge += 15.0;
    if (count >= 4) charge += 10.0;
    if (count >= 5) charge += (count - 4) * 5.0;
    return charge;
  }

  bool _isComforterClean(int idx) =>
      _services[idx].title.toLowerCase().contains('comfort');

  double _getPerPcsPrice(int idx) {
    final rp = widget.reorderParams;
    if (rp != null) {
      return (rp.totalPrice - _kServiceCharge + rp.discountAmount) / rp.itemCount;
    }
    return _services[idx].price;
  }

  double get _subtotal {
    double total = 0.0;
    for (final idx in _selectedServiceIndices) {
      if (_isComforterClean(idx)) {
        final sizes = _comforterQuantities[idx] ?? {};
        sizes.forEach((size, qty) {
          double multiplier = 1.0;
          switch (size) {
            case 'Single': multiplier = 0.5; break;
            case 'Twin XL': multiplier = 0.75; break;
            case 'Double': multiplier = 1.0; break;
            case 'Queen': multiplier = 1.5; break;
            case 'King': multiplier = 2.0; break;
          }
          total += (_getPerPcsPrice(idx) * multiplier) * qty;
        });
      } else {
        final qty = _serviceQuantities[idx] ?? 1;
        total += _getPerPcsPrice(idx) * qty;
      }
    }
    return total;
  }

  int get _effectiveQuantity {
    final rp = widget.reorderParams;
    if (rp != null) return _reorderQuantity;
    
    int total = 0;
    for (final idx in _selectedServiceIndices) {
      if (_isComforterClean(idx)) {
        final sizes = _comforterQuantities[idx] ?? {};
        total += sizes.values.fold(0, (sum, val) => sum + val);
      } else {
        total += _serviceQuantities[idx] ?? 1;
      }
    }
    return total;
  }

  double get _totalPrice =>
      (_subtotal + _kServiceCharge - _discountAmount).clamp(0.0, double.infinity);

  bool get _cardAvailable => _totalPrice >= _kStripeMinAmount;

  bool get _isExpress =>
      _selectedServiceIndices.any((idx) => _services[idx].category == 'Express');

  List<String> get _categories =>
      _selectedServiceIndices.map((idx) => _services[idx].category).toSet().toList();

  String get _serviceName {
    if (_selectedServiceIndices.isEmpty) return '';
    if (_selectedServiceIndices.length == 1) {
      return _services[_selectedServiceIndices.first].title;
    }
    return '${_selectedServiceIndices.length} Services Selected';
  }

  bool get _canProceed {
    if (_isCheckingAvailability) return false;
    switch (_step) {
      case 1: return _selectedServiceIndices.isNotEmpty;
      case 2: return _storeIdx != null;
      case 3:
        return _pickupTime != 'Select time' &&
            _deliveryTime != 'Select time' &&
            _pickupTimeSlots.isNotEmpty &&
            _deliveryTimeSlots.isNotEmpty;
      case 4: return _addrCtrl.text.trim().isNotEmpty;
      case 5: return _effectiveQuantity > 0;
      case 6: return true;
      default: return false;
    }
  }

  String get _stepTitle => const [
    'Select Service',
    'Select Store',
    'Schedule',
    'Address Selection',
    'Confirm Service',
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
      _reorderQuantity = rp.itemCount;
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
      final svcs = await sl<ServicesRemoteDataSource>().getAllServices();
      final strs = await sl<StoresRemoteDataSource>().getAllStores();

      Position? userPos;
      try {
        var status = await Geolocator.checkPermission();
        if (status == LocationPermission.denied) {
          status = await Geolocator.requestPermission();
        }
        if (status == LocationPermission.always || status == LocationPermission.whileInUse) {
          userPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        }
      } catch (_) {}

      if (!mounted) return;

      final services = svcs;
      List<StoreEntity> stores = strs;

      if (userPos != null) {
        stores = strs.map((s) {
          if (s.latitude != null && s.longitude != null) {
            final distMeters = Geolocator.distanceBetween(
              userPos!.latitude, userPos!.longitude,
              s.latitude!, s.longitude!,
            );
            return StoreModel(
              id: s.id,
              name: s.name,
              address: s.address,
              city: s.city,
              phone: s.phone,
              distanceKm: distMeters / 1000.0,
              latitude: s.latitude,
              longitude: s.longitude,
              isActive: s.isActive,
              logoUrl: s.logoUrl,
              openHour: s.openHour,
              closeHour: s.closeHour,
              slotCapacity: s.slotCapacity,
              slotIntervalHours: s.slotIntervalHours,
              pickupBufferHours: s.pickupBufferHours,
              advanceBookingDays: s.advanceBookingDays,
              bookings: s.bookings,
            );
          }
          return s;
        }).toList();
        stores.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }

      int? preIdx;
      if (widget.preSelectedServiceId != null) {
        final idx =
        services.indexWhere((s) => s.id == widget.preSelectedServiceId);
        if (idx != -1) preIdx = idx;
      }

      setState(() {
        _services = services;
        _stores = stores;
        if (preIdx != null) {
          _selectedServiceIndices.add(preIdx);
          if (_isComforterClean(preIdx)) {
            _comforterQuantities[preIdx] = {'Single': 0, 'Twin XL': 0, 'Double': 1, 'Queen': 0, 'King': 0};
          } else {
            _serviceQuantities[preIdx] = 1;
          }
        }
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

  Future<String?> _validateAndApplyCoupon(String code) async {
    _couponCompleter = Completer<String?>();
    final List<String> currentServiceIds = [];
    final Map<String, double> subtotals = {};
    for (final idx in _selectedServiceIndices) {
      final sId = _services[idx].id;
      currentServiceIds.add(sId);
      
      double price = 0.0;
      if (_isComforterClean(idx)) {
        final sizes = _comforterQuantities[idx] ?? {};
        sizes.forEach((size, count) {
          double multiplier = 1.0;
          switch (size) {
            case 'Single': multiplier = 0.5; break;
            case 'Twin XL': multiplier = 0.75; break;
            case 'Double': multiplier = 1.0; break;
            case 'Queen': multiplier = 1.5; break;
            case 'King': multiplier = 2.0; break;
          }
          price += (_getPerPcsPrice(idx) * multiplier) * count;
        });
      } else {
        final qty = _serviceQuantities[idx] ?? 1;
        price = _getPerPcsPrice(idx) * qty;
      }
      subtotals[sId] = price;
    }

    final params = ValidateCouponParams(
      code: code,
      serviceIds: currentServiceIds,
      serviceSubtotals: subtotals,
      orderBeforeDiscount: _subtotal,
    );
    context.read<CheckoutCubit>().validateCoupon(params);
    return _couponCompleter!.future;
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _couponTargetServiceId = null;
    });
  }

  // ─── Schedule helpers ─────────────────────────────────────────────────────────

  Future<void> _refreshTimeSlots() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    if (mounted) setState(() => _isCheckingAvailability = true);

    List<String> slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
      storeId, _pickupDate, isPickup: true, categories: _categories,
    );

    while (slots.isEmpty) {
      _pickupDate = BusinessLogicUtils.getNextBusinessDay(_pickupDate);
      slots = await BusinessLogicUtils.getAvailableSlotsFiltered(
        storeId, _pickupDate, isPickup: true, categories: _categories,
      );
    }

    if (mounted) {
      setState(() {
        _pickupTimeSlots = slots;
        _pickupTime =
        _pickupTimeSlots.isNotEmpty ? _pickupTimeSlots.first : 'Select time';
        _isCheckingAvailability = false;
      });
    }

    await _syncDelivery();
  }

  Future<void> _syncDelivery() async {
    if (_storeIdx == null && widget.reorderParams == null) return;
    final storeId = widget.reorderParams?.storeId ?? _stores[_storeIdx!].id;

    final minRequired = BusinessLogicUtils.getMinDeliveryDate(
      _pickupDate, _pickupTime, _serviceName,
      categories: _categories, totalItems: _effectiveQuantity,
    );
    if (_deliveryDate.isBefore(minRequired)) _deliveryDate = minRequired;

    List<String> slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
      storeId, _deliveryDate,
      pickupDate: _pickupDate, pickupTime: _pickupTime,
      serviceName: _serviceName, categories: _categories, totalItems: _effectiveQuantity,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        storeId, _deliveryDate,
        pickupDate: _pickupDate, pickupTime: _pickupTime,
        serviceName: _serviceName, categories: _categories, totalItems: _effectiveQuantity,
      );
    }

    if (mounted) {
      setState(() {
        _deliveryTimeSlots = slots;
        _deliveryTime = _deliveryTimeSlots.isNotEmpty
            ? _deliveryTimeSlots.first
            : 'Select time';
      });
    }
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
      serviceName: _serviceName, categories: _categories, totalItems: _effectiveQuantity,
    );

    while (slots.isEmpty) {
      _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      while (BusinessLogicUtils.isClosedDay(_deliveryDate)) {
        _deliveryDate = _deliveryDate.add(const Duration(days: 1));
      }
      slots = await BusinessLogicUtils.getDeliverySlotsFiltered(
        storeId, _deliveryDate,
        pickupDate: _pickupDate, pickupTime: _pickupTime,
        serviceName: _serviceName, categories: _categories, totalItems: _effectiveQuantity,
      );
    }

    if (mounted) {
      setState(() {
        _deliveryTimeSlots = slots;
        _deliveryTime = _deliveryTimeSlots.isNotEmpty
            ? _deliveryTimeSlots.first
            : 'Select time';
        _isCheckingAvailability = false;
      });
    }
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
      orderValue: _totalPrice, orderItemCount: _effectiveQuantity,
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
        (_selectedServiceIndices.isEmpty || _storeIdx == null)) {
      return;
    }
    
    _ordersToPlace = widget.reorderParams != null ? 1 : _selectedServiceIndices.length;
    _ordersPlacedSuccessfully = 0;

    if (_paymentMethod == PaymentMethod.cashOnDelivery) {
      _placeAllOrders(stripe: false);
    } else {
      _handleStripePayment();
    }
  }

  void _placeAllOrders({required bool stripe}) {
    final method = stripe ? PaymentMethod.stripe : PaymentMethod.cashOnDelivery;
    final rp = widget.reorderParams;
    
    if (rp != null) {
      context.read<OrdersBloc>().add(
        OrderPlaceRequested(_buildParams(
          method: method,
          serviceId: rp.serviceId,
          qty: _effectiveQuantity,
          price: _totalPrice,
          serviceChargeToApply: _kServiceCharge,
          discountToApply: _discountAmount,
        )),
      );
      return;
    }

    final int count = _selectedServiceIndices.length;
    final double scPerOrder = count > 0 ? _kServiceCharge / count : 0.0;
    final String sharedGroupId = const Uuid().v4();

    for (final idx in _selectedServiceIndices) {
      int qty = 0;
      double price = 0.0;
      
      if (_isComforterClean(idx)) {
        final sizes = _comforterQuantities[idx] ?? {};
        qty = sizes.values.fold(0, (a, b) => a + b);
        double total = 0.0;
        sizes.forEach((size, count) {
          double multiplier = 1.0;
          switch (size) {
            case 'Single': multiplier = 0.5; break;
            case 'Twin XL': multiplier = 0.75; break;
            case 'Double': multiplier = 1.0; break;
            case 'Queen': multiplier = 1.5; break;
            case 'King': multiplier = 2.0; break;
          }
          total += (_getPerPcsPrice(idx) * multiplier) * count;
        });
        price = total;
      } else {
        qty = _serviceQuantities[idx] ?? 1;
        price = _getPerPcsPrice(idx) * qty;
      }

      double appliedDiscount = 0.0;
      if (_discountAmount > 0) {
        if (_couponTargetServiceId != null) {
          if (_services[idx].id == _couponTargetServiceId) {
            appliedDiscount = _discountAmount;
          }
        } else {
          // Global coupon: apply proportionally based on service price
          appliedDiscount = _subtotal > 0 ? (price / _subtotal) * _discountAmount : 0.0;
        }
      }

      context.read<OrdersBloc>().add(
        OrderPlaceRequested(_buildParams(
          method: method,
          serviceId: _services[idx].id,
          qty: qty,
          price: price,
          serviceChargeToApply: scPerOrder,
          discountToApply: appliedDiscount,
          idx: idx,
          groupId: sharedGroupId,
        )),
      );
    }
  }

  PlaceOrderParams _buildParams({
    required PaymentMethod method,
    required String serviceId,
    required int qty,
    required double price,
    required double serviceChargeToApply,
    required double discountToApply,
    int? idx,
    String? groupId,
  }) {
    final rp = widget.reorderParams;
    final finalPrice = price + serviceChargeToApply - discountToApply;
    
    return PlaceOrderParams(
      serviceId: serviceId,
      storeId: rp?.storeId ?? _stores[_storeIdx!].id,
      itemCount: qty,
      totalPrice: finalPrice.clamp(0.0, double.infinity),
      pickupAddress: AddressEntity(label: 'Custom', address: _addrCtrl.text.trim()),
      deliveryAddress: AddressEntity(label: 'Custom', address: _addrCtrl.text.trim()),
      pickupDate: _pickupDate,
      pickupTime: _pickupTime == 'Select time' ? null : _pickupTime,
      deliveryDate: _deliveryDate,
      deliveryTime: _deliveryTime == 'Select time' ? null : _deliveryTime,
      specialInstructions: _buildSpecialInstructions(idx),
      paymentMethod: method,
      couponCode: discountToApply > 0 ? _appliedCoupon : null,
      discountAmount: discountToApply,
      groupId: groupId,
    );
  }

  String? _buildSpecialInstructions(int? idx) {
    final note = _noteCtrl.text.trim();
    if (idx != null && _isComforterClean(idx)) {
      final sizes = _comforterQuantities[idx] ?? {};
      final sizeDesc = sizes.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.value}x ${e.key}')
          .join(', ');
      if (sizeDesc.isEmpty) return note.isEmpty ? null : note;
      if (note.isEmpty) return 'Comforters: $sizeDesc';
      return 'Comforters: $sizeDesc\n$note';
    }
    return note.isEmpty ? null : note;
  }

  Future<void> _handleStripePayment() async {
    final svcTitle = widget.reorderParams?.serviceName ?? _serviceName;
    final params = CreatePaymentIntentParams(
      amount: _totalPrice,
      serviceTitle: svcTitle,
    );
    context.read<CheckoutCubit>().createPaymentIntent(params);
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

    return MultiBlocListener(
      listeners: [
        BlocListener<OrdersBloc, OrdersState>(
          listener: (context, state) {
            if (state is OrderPlaced) {
              _ordersPlacedSuccessfully++;
              if (_ordersPlacedSuccessfully == _ordersToPlace) {
                context.read<OrdersBloc>().add(const OrdersLoadRequested());
                context.pop();
                context.go(
                  RoutesName.confirmedOrdersNavigate,
                  extra: {'orderNumber': state.orderNumber, 'orderId': state.orderId},
                );
              }
            } else if (state is OrdersError) {
              setState(() => _stripeLoading = false);
              AppSnackBar.show(context, state.message, isError: true);
            }
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) async {
            if (state is CheckoutCouponValidated) {
              setState(() {
                _appliedCoupon = state.couponCode.toUpperCase();
                _discountAmount = state.discountAmount;
                _couponTargetServiceId = state.targetServiceId;
                if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
              });
              _couponCompleter?.complete(null);
            } else if (state is CheckoutCouponError) {
              _couponCompleter?.complete(state.message);
            } else if (state is CheckoutPaymentIntentCreating) {
              setState(() {
                _stripeLoading = true;
                _stripeError = null;
              });
            } else if (state is CheckoutPaymentIntentCreated) {
              try {
                await Stripe.instance.initPaymentSheet(
                  paymentSheetParameters: SetupPaymentSheetParameters(
                    paymentIntentClientSecret: state.clientSecret,
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
                  _placeAllOrders(stripe: true);
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
                  AppSnackBar.show(context, 'Payment setup failed. Please try again.', isError: true);
                }
              }
            } else if (state is CheckoutPaymentIntentError) {
              setState(() {
                _stripeLoading = false;
                _stripeError = state.message;
              });
              AppSnackBar.show(context, state.message, isError: true);
            }
          },
        ),
      ],
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
                  AppStepProgress(step: _step, totalSteps: 6, isDark: isDark),
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
                        6,
                            (i) => SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildStep(i + 1, isDark),
                        ),
                      ),
                    ),
                  ),
                  AppStepperBottomNav(
                    step: _step,
                    totalSteps: 6,
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
                      if (_step < 6) {
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
              selected: _selectedServiceIndices.contains(i),
              isDark: isDark,
              onTap: () => setState(() {
                if (_selectedServiceIndices.contains(i)) {
                  _selectedServiceIndices.remove(i);
                  _serviceQuantities.remove(i);
                  _comforterQuantities.remove(i);
                } else {
                  _selectedServiceIndices.add(i);
                  if (_isComforterClean(i)) {
                    _comforterQuantities[i] = {'Single': 0, 'Twin XL': 0, 'Double': 1, 'Queen': 0, 'King': 0};
                  } else {
                    _serviceQuantities[i] = 1;
                  }
                }
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
            categories: _categories, totalItems: _effectiveQuantity,
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

      case 5:
        final rp = widget.reorderParams;
        return PoConfirmationStep(
          subtotal: _subtotal,
          serviceCharge: _kServiceCharge,
          totalPrice: _totalPrice,
          isDark: isDark,
          selectedIndices: _selectedServiceIndices.toList(),
          services: _services,
          serviceQuantities: _serviceQuantities,
          comforterQuantities: _comforterQuantities,
          reorderParams: rp,
          onAddService: (idx) => setState(() {
            _selectedServiceIndices.add(idx);
            if (_isComforterClean(idx)) {
              _comforterQuantities[idx] = {'Single': 0, 'Twin XL': 0, 'Double': 1, 'Queen': 0, 'King': 0};
            } else {
              _serviceQuantities[idx] = 1;
            }
          }),
          onRemoveService: (idx) => setState(() {
            _selectedServiceIndices.remove(idx);
            _serviceQuantities.remove(idx);
            _comforterQuantities.remove(idx);
            if (_selectedServiceIndices.isEmpty) {
              _moveToStep(1);
            }
          }),
          onComforterQtyChanged: (idx, s, q) => setState(() {
            _comforterQuantities[idx]?[s] = q;
            if (_appliedCoupon != null) _removeCoupon();
            if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
          }),
          onQuantityChanged: (idx, q) => setState(() {
            if (idx == -1) {
              _reorderQuantity = q;
            } else {
              _serviceQuantities[idx] = q;
            }
            if (_appliedCoupon != null) _removeCoupon();
            if (!_cardAvailable) _paymentMethod = PaymentMethod.cashOnDelivery;
          }),
          serviceName: rp?.serviceName ?? _serviceName,
          storeName: rp?.storeName ??
              (_storeIdx != null ? _stores[_storeIdx!].name : ''),
          pickupInfo:
          '${BusinessLogicUtils.formatDate(_pickupDate)} at $_pickupTime',
          deliveryInfo:
          '${BusinessLogicUtils.formatDate(_deliveryDate)} at $_deliveryTime',
        );

      default:
        return PoPaymentMethodStep(
          selectedMethod: _paymentMethod,
          subtotal: _subtotal,
          serviceCharge: _kServiceCharge,
          totalPrice: _totalPrice,
          discountAmount: _discountAmount,
          cardAvailable: _cardAvailable,
          isDark: isDark,
          stripeError: _stripeError,
          appliedCoupon: _appliedCoupon,
          selectedIndices: _selectedServiceIndices.toList(),
          services: _services,
          serviceQuantities: _serviceQuantities,
          comforterQuantities: _comforterQuantities,
          serviceName: widget.reorderParams?.serviceName ?? _serviceName,
          storeName: widget.reorderParams?.storeName ??
              (_storeIdx != null ? _stores[_storeIdx!].name : ''),
          pickupInfo: '${BusinessLogicUtils.formatDate(_pickupDate)} at $_pickupTime',
          deliveryInfo: '${BusinessLogicUtils.formatDate(_deliveryDate)} at $_deliveryTime',
          onMethodChanged: (m) => setState(() => _paymentMethod = m),
          onApplyCoupon: _validateAndApplyCoupon,
          onRemoveCoupon: _removeCoupon,
        );
    }
  }
}
