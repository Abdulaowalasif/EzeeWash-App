import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Added for Factory
import 'package:flutter/gestures.dart';   // Added for EagerGestureRecognizer
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class TrackOrderScreen extends StatefulWidget {
  const TrackOrderScreen({super.key});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  bool showMap = true;
  GoogleMapController? _mapController;

  final steps = [
    TimelineStep(
      title: "Order Placed",
      description: "Your order has been confirmed",
      time: "Today, 1:45 PM",
      icon: Icons.check_circle,
      isDone: true,
    ),
    TimelineStep(
      title: "Picked Up",
      description: "Items collected from your location",
      time: "Today, 2:30 PM",
      icon: Icons.shopping_bag,
      isDone: true,
    ),
    TimelineStep(
      title: "In Transit",
      description: "On the way to laundry facility",
      time: "Today, 3:15 PM",
      icon: Icons.local_shipping,
      isDone: true,
      activeBadge: "Active",
    ),
    TimelineStep(
      title: "Processing",
      description: "Being cleaned and processed",
      time: "Estimated: Today, 4:00 PM",
      icon: Icons.restart_alt_sharp,
      isDone: false,
    ),
    TimelineStep(
      title: "Out for Delivery",
      description: "On the way to your location",
      time: "Estimated: Tomorrow, 9:00 AM",
      icon: Icons.directions_car_filled,
      isDone: false,
    ),
    TimelineStep(
      title: "Delivered",
      description: "Order completed successfully",
      time: "Estimated: Tomorrow, 10:00 AM",
      icon: Icons.delivery_dining,
      isDone: false,
    ),
  ];

  final LatLng initialLocation = const LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Track Order', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 🔵 Top Order Info Card
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order ID", style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text("#LN2847", style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Iconsax.truck_fast, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildHeaderInfo("Service", "Wash & Fold"),
                      const SizedBox(width: 12),
                      _buildHeaderInfo("Status", "In Transit"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔘 Toggle Map / Timeline
            _buildToggle(isDark),

            const SizedBox(height: 24),

            // 📍 Map or Timeline
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: showMap ? _buildMapView(isDark) : _buildTimelineView(isDark),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleBtn("Live Map", Icons.location_on_outlined, true),
          const SizedBox(width: 8),
          _toggleBtn("Timeline", Icons.timelapse_outlined, false),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, IconData icon, bool isMap) {
    bool isSelected = showMap == isMap;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showMap = isMap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(bool isDark) {
    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(target: initialLocation, zoom: 14.5),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              // 👇 This is the fix to allow panning the map inside a scroll view
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildDeliveryInfoCard(isDark),
      ],
    );
  }

  Widget _buildDeliveryInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Delivery Information", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _infoTile(Icons.location_on_outlined, "Delivery Address", "123 Main St, Apt 4B", Colors.blue, isDark),
          _infoTile(Icons.timelapse_outlined, "Estimated Delivery", "Tomorrow, 10:00 AM", Colors.green, isDark),
          _infoTile(Icons.storefront, "Processing Store", "Downtown Store", Colors.purple, isDark),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String sub, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey.shade500)),
                Text(sub, style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(bool isDark) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order Timeline", style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ...List.generate(
          steps.length,
              (index) => TimelineTile(
            step: steps[index],
            isLast: index == steps.length - 1,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
              label: Text("Cancel Order", style: GoogleFonts.alexandria(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class TimelineStep {
  final String title, description, time;
  final IconData icon;
  final bool isDone;
  final String? activeBadge;

  TimelineStep({required this.title, required this.description, required this.time, required this.icon, required this.isDone, this.activeBadge});
}

class TimelineTile extends StatelessWidget {
  final TimelineStep step;
  final bool isLast;
  final bool isDark;

  const TimelineTile({super.key, required this.step, required this.isLast, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: step.isDone ? primaryGradient : null,
                    color: step.isDone ? null : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    boxShadow: step.isDone ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8)] : [],
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: step.isDone ? primaryColor : Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: step.isDone ? primaryColor.withOpacity(0.2) : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(step.title, style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (step.activeBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                          child: Text(step.activeBadge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.description, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: primaryColor.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(step.time, style: GoogleFonts.alexandria(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}