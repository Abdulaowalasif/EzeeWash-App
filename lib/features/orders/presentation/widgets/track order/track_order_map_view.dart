// lib/features/orders/presentation/widgets/track_order_map_view.dart
//
// Google Maps view that shows real-time rider position, customer location,
// and a dashed polyline between them. Handles geocoding, location permission,
// and loading/denied overlay states.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/order_entity.dart';
import '../../screens/track_order_screen.dart' show OrderPhase;
import 'track_order_rider_sheet.dart';

class TrackOrderMapView extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final OrderPhase phase;
  final String? activeRiderId;

  const TrackOrderMapView({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
    this.activeRiderId,
  });

  @override
  State<TrackOrderMapView> createState() => _TrackOrderMapViewState();
}

class _TrackOrderMapViewState extends State<TrackOrderMapView> {
  final Completer<GoogleMapController> _cc = Completer();
  GoogleMapController? _mapCtrl;
  LatLng? _customerLoc;
  LatLng? _riderPos;
  bool _loading = true;
  bool _denied = false;
  StreamSubscription? _sub;
  Map<String, dynamic>? _riderRow;

  static const LatLng _dhaka = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    if (widget.order.riderLat != null && widget.order.riderLng != null) {
      _riderPos = LatLng(widget.order.riderLat!, widget.order.riderLng!);
    }
    _init();
  }

  @override
  void didUpdateWidget(TrackOrderMapView old) {
    super.didUpdateWidget(old);
    if (old.activeRiderId != widget.activeRiderId) _listenRider();
    if (old.phase != widget.phase) _fit();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final addr = widget.phase == OrderPhase.riderComingToDeliver
          ? (widget.order.deliveryAddress ?? widget.order.pickupAddress)
          : widget.order.pickupAddress;
      if (addr.isNotEmpty) {
        final locs = await locationFromAddress(addr);
        if (locs.isNotEmpty) {
          _customerLoc = LatLng(locs.first.latitude, locs.first.longitude);
        }
      }
    } catch (_) {}

    if (_customerLoc == null) {
      try {
        final svcEnabled = await Geolocator.isLocationServiceEnabled();
        if (svcEnabled) {
          var perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied) {
            perm = await Geolocator.requestPermission();
          }
          if (perm != LocationPermission.denied &&
              perm != LocationPermission.deniedForever) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            _customerLoc = LatLng(pos.latitude, pos.longitude);
          }
        }
      } catch (_) {}
    }

    _listenRider();

    if (mounted) {
      setState(() {
        _loading = false;
        _denied = _customerLoc == null;
      });
      _fit();
    }
  }

  void _listenRider() {
    _sub?.cancel();
    if (widget.activeRiderId == null) return;
    _sub = Supabase.instance.client
        .from('riders')
        .stream(primaryKey: ['id'])
        .eq('id', widget.activeRiderId!)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final row = data.first;
        final lat = (row['current_lat'] as num?)?.toDouble();
        final lng = (row['current_lng'] as num?)?.toDouble();
        setState(() {
          _riderRow = row;
          if (lat != null && lng != null) {
            _riderPos = LatLng(lat, lng);
          }
        });
        _fit();
      }
    });
  }

  void _onRiderMarkerTap() {
    if (_riderRow == null) return;
    final distKm = (_customerLoc != null && _riderPos != null)
        ? Geolocator.distanceBetween(
              _riderPos!.latitude,
              _riderPos!.longitude,
              _customerLoc!.latitude,
              _customerLoc!.longitude,
            ) /
            1000
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackOrderRiderSheet(
        order: widget.order,
        isDark: widget.isDark,
        phase: widget.phase,
        initialRiderRow: _riderRow!,
        initialRiderPos: _riderPos,
        initialDistanceKm: distKm,
        customerLoc: _customerLoc,
      ),
    );
  }

  Future<void> _fit() async {
    if (_customerLoc == null) return;
    final ctrl = await _cc.future;
    if (_riderPos != null) {
      final sw = LatLng(
        math.min(_customerLoc!.latitude, _riderPos!.latitude),
        math.min(_customerLoc!.longitude, _riderPos!.longitude),
      );
      final ne = LatLng(
        math.max(_customerLoc!.latitude, _riderPos!.latitude),
        math.max(_customerLoc!.longitude, _riderPos!.longitude),
      );
      await ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: sw, northeast: ne),
          70,
        ),
      );
    } else {
      await ctrl
          .animateCamera(CameraUpdate.newLatLngZoom(_customerLoc!, 15));
    }
  }

  Set<Marker> get _markers {
    final m = <Marker>{};
    if (_customerLoc != null) {
      m.add(Marker(
        markerId: const MarkerId('customer'),
        position: _customerLoc!,
        infoWindow: InfoWindow(
          title: widget.phase == OrderPhase.riderComingToDeliver
              ? 'Your Address (Delivery)'
              : 'Your Address (Pickup)',
        ),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (_riderPos != null) {
      m.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderPos!,
        infoWindow: InfoWindow(
          title: widget.phase == OrderPhase.riderComingToDeliver
              ? 'Rider • Delivering'
              : 'Rider • Coming to Pickup',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
        onTap: _onRiderMarkerTap,
      ));
    }
    return m;
  }

  Set<Polyline> get _polylines {
    if (_customerLoc == null || _riderPos == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_riderPos!, _customerLoc!],
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Widget _buildMap() => GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _customerLoc ?? _dhaka,
          zoom: 14,
        ),
        onMapCreated: (ctrl) {
          if (!_cc.isCompleted) _cc.complete(ctrl);
          _mapCtrl = ctrl;
          if (widget.isDark) ctrl.setMapStyle(AppConstants.darkMapStyle);
          _fit();
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        gestureRecognizers: {
          Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      );

  Widget _loadingOverlay() => Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _dhaka, zoom: 12),
            onMapCreated: (ctrl) {
              if (!_cc.isCompleted) _cc.complete(ctrl);
              _mapCtrl = ctrl;
              if (widget.isDark)
                ctrl.setMapStyle(AppConstants.darkMapStyle);
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            gestureRecognizers: {
              Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),
          Positioned.fill(
            child: Container(
              color: widget.isDark
                  ? Colors.black.withOpacity(0.55)
                  : Colors.white.withOpacity(0.72),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Locating address…',
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        color: widget.isDark
                            ? Colors.white70
                            : AppColors.lightSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _deniedOverlay() => Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _dhaka, zoom: 12),
            onMapCreated: (ctrl) {
              if (!_cc.isCompleted) _cc.complete(ctrl);
              _mapCtrl = ctrl;
              if (widget.isDark)
                ctrl.setMapStyle(AppConstants.darkMapStyle);
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            gestureRecognizers: {
              Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    Icons.location_searching_rounded,
                    size: 16,
                    color: widget.isDark
                        ? Colors.white70
                        : AppColors.lightSubtext,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not resolve delivery address',
                      style: GoogleFonts.alexandria(
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
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: widget.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: _loading
                    ? _loadingOverlay()
                    : _denied
                        ? _deniedOverlay()
                        : _buildMap(),
              ),
            ),
          ),
          // Phase badge (top-left)
          Positioned(
            top: 14,
            left: 14,
            child: _MapBadge(
              icon: widget.phase == OrderPhase.riderComingToDeliver
                  ? Iconsax.truck_fast
                  : Iconsax.car,
              label: widget.phase == OrderPhase.riderComingToDeliver
                  ? 'Rider delivering'
                  : 'Rider picking up',
            ),
          ),
          // Tap hint (top-right)
          if (_riderPos != null)
            const Positioned(
              top: 14,
              right: 14,
              child: _MapBadge(
                icon: Icons.touch_app_rounded,
                label: 'Tap rider',
              ),
            ),
        ],
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.62),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.alexandria(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}
