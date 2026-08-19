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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/rider_tracking_bloc.dart';
import '../../bloc/rider_tracking_event.dart';
import '../../bloc/rider_tracking_state.dart';
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
  Map<String, dynamic>? _riderRow;

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
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
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
    if (widget.activeRiderId == null) return;
    context.read<RiderTrackingBloc>().add(
      RiderTrackingStarted(widget.activeRiderId!),
    );
  }

  void _onRiderStateChanged(BuildContext context, RiderTrackingState state) {
    if (state is RiderTrackingLoaded) {
      final row = state.riderRow;
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
      builder: (_) => BlocProvider.value(
        value: context.read<RiderTrackingBloc>(),
        child: TrackOrderRiderSheet(
          order: widget.order,
          isDark: widget.isDark,
          phase: widget.phase,
          initialRiderRow: _riderRow!,
          initialRiderPos: _riderPos,
          initialDistanceKm: distKm,
          customerLoc: _customerLoc,
        ),
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
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(_customerLoc!, 15));
    }
  }

  Set<Marker> get _markers {
    final m = <Marker>{};
    if (_customerLoc != null) {
      m.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLoc!,
          infoWindow: InfoWindow(
            title: widget.phase == OrderPhase.riderComingToDeliver
                ? 'Your Address (Delivery)'
                : 'Your Address (Pickup)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    if (_riderPos != null) {
      m.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: _riderPos!,
          infoWindow: InfoWindow(
            title: widget.phase == OrderPhase.riderComingToDeliver
                ? 'Rider • Delivering'
                : 'Rider • Coming to Pickup',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: _onRiderMarkerTap,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_denied || _customerLoc == null) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Location Access Needed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We need your location to show the map.',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return BlocListener<RiderTrackingBloc, RiderTrackingState>(
      listener: _onRiderStateChanged,
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _customerLoc!,
                  zoom: 15,
                ),
                onMapCreated: (c) {
                  _cc.complete(c);
                  _mapCtrl = c;
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
                  Factory<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
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
        ),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
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
