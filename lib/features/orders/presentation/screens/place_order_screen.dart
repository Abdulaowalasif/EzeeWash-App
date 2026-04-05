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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../../../core/widgets/gradient_app_bar.dart';
import '../../domain/entities/place_orders_params.dart';
import '../bloc/order_event.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_state.dart';
import '../screens/order_screen.dart' show ReorderParams;

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

  List<String> _pickupTimeSlots = [];
  List<String> _deliveryTimeSlots = [];

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

    final rp = widget.reorderParams;
    if (rp != null) {
      _quantity = rp.itemCount;
      _pickupDate = rp.pickupDate;
      _pickupTime = rp.pickupTime;
      _deliveryDate = rp.deliveryDate;
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
      _pickupDate = _minPickupDate;
      _pickupTime = 'Select time';
      _deliveryDate = _pickupDate.add(
        const Duration(days: 1),
      ); // Initial placeholder
      _deliveryTime = 'Select time';
      _loadData();
    }
    _addrCtrl.addListener(() => setState(() {}));
  }

  // ─── LOGIC FIXES FOR BUSINESS HOUR TIMER ───────────────────────────────────

  bool get _isExpress =>
      _serviceIdx != null && _services[_serviceIdx!].category == 'Express';

  DateTime get _minPickupDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Cutoff at 7:00 PM (19:00). If past cutoff, next day is earliest.
    return now.hour >= 19 ? today.add(const Duration(days: 1)) : today;
  }

  DateTime get _minDeliveryDate {
    DateTime dt = _getMinDeliveryDateTime(_pickupDate, _pickupTime);
    return DateTime(dt.year, dt.month, dt.day);
  }

  String _formatHour(int h) {
    int displayHour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    String amPm = h >= 12 ? 'PM' : 'AM';
    String hourStr = displayHour.toString().padLeft(2, '0');
    return '$hourStr:00 $amPm';
  }

  int _parseHour(String timeStr) {
    if (timeStr.isEmpty || timeStr == 'Select time') return 8;
    try {
      List<String> parts = timeStr.split(' ');
      int h = int.parse(parts[0].split(':')[0]);
      if (parts.length > 1) {
        if (parts[1] == 'PM' && h != 12) h += 12;
        if (parts[1] == 'AM' && h == 12) h = 0;
      }
      return h;
    } catch (_) {
      return 8;
    }
  }

  List<String> _getPickupTimes(DateTime date) {
    final now = DateTime.now();
    int startHour = 8;
    int endHour = 19; // Latest pickup slot at 7 PM

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      // Show from current + 1h
      startHour = now.hour + 1;
      if (startHour < 8) startHour = 8;
    }

    if (startHour > endHour) return [];

    List<String> times = [];
    for (int i = startHour; i <= endHour; i++) {
      times.add(_formatHour(i));
    }
    return times;
  }

  DateTime _getMinDeliveryDateTime(DateTime pDate, String pTime) {
    int pHour = _parseHour(pTime);
    DateTime current = DateTime(pDate.year, pDate.month, pDate.day, pHour);

    // Express = 5 business hours (8am-8pm window).
    // Standard = 12 business hours (effectively 24 physical hours).
    int hoursNeeded = _isExpress ? 5 : 12;

    while (hoursNeeded > 0) {
      // If we are at or after closing (8:00 PM), move to next day opening (8:00 AM)
      if (current.hour >= 20) {
        current = DateTime(current.year, current.month, current.day + 1, 8);
      }

      // Advance by one business hour
      current = current.add(const Duration(hours: 1));
      hoursNeeded--;
    }

    return current;
  }

  List<String> _getDeliveryTimes(DateTime dDate) {
    DateTime minDelDateTime = _getMinDeliveryDateTime(_pickupDate, _pickupTime);
    int startHour = 8;
    int endHour = 20; // Delivery until 8 PM

    bool isSameAsMinDay =
        dDate.year == minDelDateTime.year &&
            dDate.month == minDelDateTime.month &&
            dDate.day == minDelDateTime.day;

    if (isSameAsMinDay) {
      startHour = minDelDateTime.hour;
      if (startHour < 8) startHour = 8;
    }

    if (startHour > endHour) return [];

    List<String> times = [];
    for (int i = startHour; i <= endHour; i++) {
      times.add(_formatHour(i));
    }
    return times;
  }

  // ─── HANDLERS ─────────────────────────────────────────────────────────────

  void _refreshTimeSlots() {
    _pickupTimeSlots = _getPickupTimes(_pickupDate);
    if (!_pickupTimeSlots.contains(_pickupTime)) {
      _pickupTime = _pickupTimeSlots.isNotEmpty
          ? _pickupTimeSlots.first
          : 'Select time';
    }

    _syncDelivery();
  }

  void _syncDelivery() {
    DateTime minD = _minDeliveryDate;
    if (_deliveryDate.isBefore(minD)) {
      _deliveryDate = minD;
    }
    _deliveryTimeSlots = _getDeliveryTimes(_deliveryDate);
    if (!_deliveryTimeSlots.contains(_deliveryTime)) {
      _deliveryTime = _deliveryTimeSlots.isNotEmpty
          ? _deliveryTimeSlots.first
          : 'Select time';
    }
  }

  void _handlePickupDateChanged(DateTime date) {
    setState(() {
      _pickupDate = date;
      _refreshTimeSlots();
    });
  }

  void _handlePickupTimeChanged(String time) {
    setState(() {
      _pickupTime = time;
      _syncDelivery();
    });
  }

  void _handleDeliveryDateChanged(DateTime date) {
    setState(() {
      _deliveryDate = date;
      _deliveryTimeSlots = _getDeliveryTimes(date);
      if (!_deliveryTimeSlots.contains(_deliveryTime)) {
        _deliveryTime = _deliveryTimeSlots.isNotEmpty
            ? _deliveryTimeSlots.first
            : 'Select time';
      }
    });
  }

  // ─── Boilerplate & UI ─────────────────────────────────────────────────────

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
          if (preIdx != null) {
            _step = 2;
            _refreshTimeSlots();
          }
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

  void _onConfirm() {
    if (widget.reorderParams == null &&
        (_serviceIdx == null || _storeIdx == null))
      return;
    if (_paymentMethod == PaymentMethod.cashOnDelivery) {
      context.read<OrdersBloc>().add(
        OrderPlaceRequested(_buildParams(method: PaymentMethod.cashOnDelivery)),
      );
    } else {
      _handleStripePayment();
    }
  }

  Future<void> _handleStripePayment() async {
    if (!mounted) return;
    setState(() {
      _stripeLoading = true;
      _stripeError = null;
    });
    try {
      final svcTitle =
          widget.reorderParams?.serviceName ?? _services[_serviceIdx!].title;
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
          // Insert order when Stripe payment fails
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
        // Insert order when Stripe setup fails
        context.read<OrdersBloc>().add(
          OrderPlaceRequested(_buildParams(method: PaymentMethod.stripe)),
        );
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
        if (state is OrderPlaced)
          context.go(
            '${RoutesName.orders}/${RoutesName.confirmedOrders}',
            extra: state.orderNumber,
          );
        else if (state is OrdersError) {
          setState(() => _stripeLoading = false);
          AppSnackBar.show(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: const GradientAppBar(
          title: 'Book Service',
        ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      if (_step == 1 ||
                          (_step == 5 && widget.reorderParams != null))
                        context.pop();
                      else
                        setState(() => _step--);
                    },
                    onNext: () {
                      if (_step == 2) {
                        _refreshTimeSlots();
                      }
                      if (_step < 5)
                        setState(() => _step++);
                      else
                        _onConfirm();
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
    if (_step == 4) return 'Address Selection';
    return [
      'Select Service',
      'Select Store',
      'Schedule',
      'Address Selection',
      'Payment',
    ][_step - 1];
  }

  String get _stepSubtitle {
    if (_step == 4)
      return _addrCtrl.text.isEmpty ? 'Set location on map' : _addrCtrl.text;
    return [
      'Choose your service',
      'Pick a store',
      'Set times',
      'Set location on map',
      'Summary & Payment',
    ][_step - 1];
  }

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
          minPickupDate: _minPickupDate,
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
          minDeliveryDate: _minDeliveryDate,
          maxDeliveryDate: null,
        );
      case 4:
        return _AddressStep(
          key: const ValueKey(4),
          addrCtrl: _addrCtrl,
          noteCtrl: _noteCtrl,
          isDark: isDark,
          onChanged: () => setState(() {}),
        );
      default:
        return _PaymentStep(
          key: const ValueKey(5),
          selectedMethod: _paymentMethod,
          perPcsPrice: _perPcsPrice,
          quantity: _quantity,
          subtotal: _subtotal,
          serviceCharge: _kServiceCharge,
          totalPrice: _totalPrice,
          cardAvailable: _cardAvailable,
          isDark: isDark,
          stripeError: _stripeError,
          serviceName:
          widget.reorderParams?.serviceName ??
              _services[_serviceIdx!].title,
          storeName:
          widget.reorderParams?.storeName ?? _stores[_storeIdx!].name,
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Schedule Step Component ──────────────────────────────────────────────────

class _ScheduleStep extends StatelessWidget {
  final DateTime pickupDate, deliveryDate;
  final DateTime? minDeliveryDate, maxDeliveryDate;
  final DateTime minPickupDate;
  final String pickupTime, deliveryTime;
  final bool isDark, isExpress;
  final List<String> pickupTimeSlots, deliveryTimeSlots;
  final ValueChanged<DateTime> onPickupDate, onDeliveryDate;
  final ValueChanged<String> onPickupTime, onDeliveryTime;

  const _ScheduleStep({
    super.key,
    required this.minPickupDate,
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
    this.minDeliveryDate,
    this.maxDeliveryDate,
  });

  static String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
          maxDate: null,
          noSlotsMessage:
          'No pickup slots available today. Please choose another date.',
        ),
        const SizedBox(height: 18),
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
          maxDate: maxDeliveryDate,
          noSlotsMessage: isExpress
              ? 'No same-day slots with 5h gap. Choose a later date.'
              : 'No delivery slots available for this date.',
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
                  DateTime initial =
                  (date != null && !date!.isBefore(firstDate))
                      ? date!
                      : firstDate;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstDate,
                    lastDate: maxDate ?? DateTime(now.year + 1),
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
          if (!hasSlots && date != null)
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      noSlotsMessage,
                      style: GoogleFonts.alexandria(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: currentDisplayTime == 'Select time'
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

// ─── Remaining Components (Address, Payment, etc.) ────────────────────────────

class _AddressStep extends StatefulWidget {
  final TextEditingController addrCtrl, noteCtrl;
  final bool isDark;
  final VoidCallback onChanged;

  const _AddressStep({
    super.key,
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
    if (status == LocationPermission.denied)
      status = await Geolocator.requestPermission();
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
                              'Location denied — enable in App Settings or drag the pin',
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
            hintText: 'Add specific notes or instructions...',
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
    super.key,
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
                        'Available for orders ৳100 or more. Add more pieces to unlock.',
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
      border: Border.all(color: AppColors.darkBorder),
    ),
    child: Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isEven) {
          final s = i ~/ 2 + 1;
          final done = s < step;
          final active = s == step;
          return Container(
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
          child: Container(
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
        boxShadow: enabled
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ]
            : [],
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
  Widget build(BuildContext context) => Container(
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