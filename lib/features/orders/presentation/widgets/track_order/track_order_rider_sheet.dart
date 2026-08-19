// lib/features/orders/presentation/widgets/track_order_rider_sheet.dart
//
// Bottom sheet that displays real-time rider information when the user
// taps the rider marker on the map. Shows stats, distance, ETA, vehicle,
// and Call / Message action buttons.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/order_shared/app_rider_avatar.dart';
import '../../../../../core/widgets/order_shared/app_rider_stat_box.dart';
import '../../../../../core/widgets/order_shared/app_sheet_action_button.dart';
import '../../../../../core/widgets/order_shared/app_info_tile.dart';
import '../../../domain/entities/order_entity.dart';
import '../../bloc/rider_tracking_bloc.dart';
import '../../bloc/rider_tracking_event.dart';
import '../../bloc/rider_tracking_state.dart';
import '../../screens/track_order_screen.dart' show OrderPhase;

class TrackOrderRiderSheet extends StatefulWidget {
  final OrderEntity order;
  final bool isDark;
  final OrderPhase phase;
  final Map<String, dynamic> initialRiderRow;
  final LatLng? initialRiderPos;
  final double? initialDistanceKm;
  final LatLng? customerLoc;

  const TrackOrderRiderSheet({
    super.key,
    required this.order,
    required this.isDark,
    required this.phase,
    required this.initialRiderRow,
    this.initialRiderPos,
    this.initialDistanceKm,
    this.customerLoc,
  });

  @override
  State<TrackOrderRiderSheet> createState() => _TrackOrderRiderSheetState();
}

class _TrackOrderRiderSheetState extends State<TrackOrderRiderSheet> {
  late Map<String, dynamic> _riderRow;
  late LatLng? _riderPos;
  late double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _riderRow = widget.initialRiderRow;
    _riderPos = widget.initialRiderPos;
    _distanceKm = widget.initialDistanceKm;
    final riderId = _riderRow['id'] as String?;
    if (riderId != null) {
      context.read<RiderTrackingBloc>().add(RiderTrackingStarted(riderId));
    }
  }

  void _onRiderStateChanged(BuildContext context, RiderTrackingState state) {
    if (state is RiderTrackingLoaded) {
      final row = state.riderRow;
      final lat = (row['current_lat'] as num?)?.toDouble();
      final lng = (row['current_lng'] as num?)?.toDouble();
      LatLng? newPos;
      double? newDist = _distanceKm;
      if (lat != null && lng != null) {
        newPos = LatLng(lat, lng);
        if (widget.customerLoc != null) {
          newDist =
              Geolocator.distanceBetween(
                lat,
                lng,
                widget.customerLoc!.latitude,
                widget.customerLoc!.longitude,
              ) /
              1000;
        }
      }
      setState(() {
        _riderRow = row;
        _riderPos = newPos;
        _distanceKm = newDist;
      });
    }
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  String get _name => _riderRow['full_name'] as String? ?? 'Your Rider';
  String? get _photo => _riderRow['avatar_url'] as String?;
  String get _phone => _riderRow['phone'] as String? ?? '';
  double get _rating => (_riderRow['rating'] as num?)?.toDouble() ?? 5.0;
  bool get _online => _riderRow['is_online'] as bool? ?? false;
  int get _trips => _riderRow['total_trips'] as int? ?? 0;
  String get _vtype => _riderRow['vehicle_type'] as String? ?? 'motorcycle';
  String? get _plate => _riderRow['vehicle_plate'] as String?;

  String get _distLabel {
    if (_distanceKm == null) return '—';
    if (_distanceKm! < 1) return '${(_distanceKm! * 1000).toInt()} m';
    return '${_distanceKm!.toStringAsFixed(1)} km';
  }

  String get _etaLabel {
    if (_distanceKm == null) return '—';
    final m = ((_distanceKm! / 25) * 60).ceil();
    return m < 2 ? '< 1 min' : '$m min';
  }

  String get _latLngLabel {
    if (_riderPos == null) return '—';
    return '${_riderPos!.latitude.toStringAsFixed(5)}, '
        '${_riderPos!.longitude.toStringAsFixed(5)}';
  }

  IconData _vehicleIcon() {
    switch (_vtype) {
      case 'bicycle':
        return Icons.pedal_bike_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }

  Future<void> _launchPhone() async {
    Navigator.pop(context);
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open dialer',
            style: GoogleFonts.alexandria(fontSize: 13),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _launchSms() async {
    Navigator.pop(context);
    final uri = Uri(scheme: 'sms', path: _phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open messaging app',
            style: GoogleFonts.alexandria(fontSize: 13),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.phase == OrderPhase.riderComingToPickup;
    return BlocListener<RiderTrackingBloc, RiderTrackingState>(
      listener: _onRiderStateChanged,
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            AppRiderAvatar(
              name: _name,
              photoUrl: _photo,
              isOnline: _online,
              size: 90,
            ),
            const SizedBox(height: 14),
            Text(
              _name,
              style: GoogleFonts.alexandria(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: widget.isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPickup ? 'Picking up your order' : 'Delivering your order',
                style: GoogleFonts.alexandria(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                AppRiderStatBox(
                  label: 'Rating',
                  value: _rating.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF59E0B),
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 10),
                AppRiderStatBox(
                  label: 'Trips',
                  value: '$_trips',
                  icon: Icons.route_rounded,
                  color: AppColors.primary,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 10),
                AppRiderStatBox(
                  label: 'ETA',
                  value: _etaLabel,
                  icon: Icons.access_time_rounded,
                  color: AppColors.success,
                  isDark: widget.isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppInfoTile(
              icon: Icons.near_me_rounded,
              color: AppColors.primary,
              title: 'Distance',
              sub: _distLabel,
              isDark: widget.isDark,
            ),
            AppInfoTile(
              icon: _vehicleIcon(),
              color: const Color(0xFF8B5CF6),
              title: 'Vehicle',
              sub:
                  '${_vtype[0].toUpperCase()}${_vtype.substring(1)}'
                  '${_plate != null ? "  •  $_plate" : ""}',
              isDark: widget.isDark,
            ),
            AppInfoTile(
              icon: Icons.location_on_rounded,
              color: AppColors.warning,
              title: 'Current Location',
              sub: _latLngLabel,
              isDark: widget.isDark,
            ),
            AppInfoTile(
              icon: Icons.circle,
              color: _online ? AppColors.success : Colors.grey,
              title: 'Status',
              sub: _online ? 'Online' : 'Offline',
              isDark: widget.isDark,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 18),
            Divider(
              height: 1,
              color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppSheetActionButton(
                    icon: Icons.call_rounded,
                    label: 'Call Rider',
                    color: AppColors.success,
                    isDark: widget.isDark,
                    enabled: _phone.isNotEmpty,
                    onTap: _launchPhone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSheetActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Message',
                    color: AppColors.primary,
                    isDark: widget.isDark,
                    enabled: _phone.isNotEmpty,
                    onTap: _launchSms,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
