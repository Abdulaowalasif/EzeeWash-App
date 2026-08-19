// lib/features/orders/presentation/widgets/place_order/po_address_step.dart
//
// Step 4 of the place-order wizard: map-based address picker + notes field.
// Handles location permission, geocoding, and map camera idle reverse-geocoding.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/app_constants.dart';

class PoAddressStep extends StatefulWidget {
  final TextEditingController addrCtrl;
  final TextEditingController noteCtrl;
  final bool isDark;
  final VoidCallback onChanged;

  const PoAddressStep({
    super.key,
    required this.addrCtrl,
    required this.noteCtrl,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<PoAddressStep> createState() => _PoAddressStepState();
}

class _PoAddressStepState extends State<PoAddressStep> {
  GoogleMapController? _mapCtrl;
  LatLng _center = const LatLng(23.8103, 90.4125);
  bool _isMoving = false;
  bool? _permGranted;

  @override
  void initState() {
    super.initState();
    _requestAndLocate();
  }

  Future<void> _requestAndLocate() async {
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (status == LocationPermission.always ||
        status == LocationPermission.whileInUse) {
      setState(() => _permGranted = true);
      await _goToCurrentLocation();
    } else {
      setState(() => _permGranted = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
        duration: const Duration(seconds: 1),
      );
      _reverseGeocode(target);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty && mounted) {
        final p = marks[0];
        widget.addrCtrl.text = '${p.street}, ${p.subLocality}, ${p.locality}';
        widget.onChanged();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map container
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
                    target: _center,
                    zoom: 14,
                  ),
                  myLocationEnabled: _permGranted == true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  style: widget.isDark ? AppConstants.darkMapStyle : null,
                  onMapCreated: (c) => _mapCtrl = c,
                  onCameraMoveStarted: () => setState(() => _isMoving = true),
                  onCameraMove: (p) => _center = p.target,
                  onCameraIdle: () {
                    setState(() => _isMoving = false);
                    _reverseGeocode(_center);
                  },
                ),
                // Permission denied banner
                if (_permGranted == false)
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
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
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
                // Animated pin
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
                      child: const Icon(
                        Icons.location_on,
                        size: 45,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // My location FAB
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: widget.isDark
                        ? AppColors.darkSurface
                        : Colors.white,
                    onPressed: _goToCurrentLocation,
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
        // Notes field
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
