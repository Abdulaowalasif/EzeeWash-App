import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

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
      iconColor: Colors.blue.shade700,
      backgroundColor: Colors.blue.shade50,
    ),
    TimelineStep(
      title: "Picked Up",
      description: "Items collected from your location",
      time: "Today, 2:30 PM",
      icon: Icons.shopping_bag,
      iconColor: Colors.blue.shade700,
      backgroundColor: Colors.blue.shade50,
    ),
    TimelineStep(
      title: "In Transit",
      description: "On the way to laundry facility",
      time: "Today, 3:15 PM",
      icon: Icons.local_shipping,
      iconColor: Colors.green.shade700,
      backgroundColor: Colors.green.shade50,
      activeBadge: "Active",
    ),
    TimelineStep(
      title: "Processing",
      description: "Being cleaned and processed",
      time: "Estimated: Today, 4:00 PM",
      icon: Icons.restart_alt_sharp,
      iconColor: Colors.grey.withOpacity(0.2),
      backgroundColor: Colors.grey.withOpacity(0.2),
    ),
    TimelineStep(
      title: "Out for Delivery",
      description: "On the way to your location",
      time: "Estimated: Tomorrow, 9:00 AM",
      icon: Icons.directions_car_filled,
      iconColor: Colors.grey.withOpacity(0.2),
      backgroundColor: Colors.grey.withOpacity(0.2),
    ),
    TimelineStep(
      title: "Delivered",
      description: "Order completed successfully",
      time: "Estimated: Tomorrow, 10:00 AM",
      icon: Icons.delivery_dining,
      iconColor: Colors.grey.withOpacity(0.2),
      backgroundColor: Colors.grey.withOpacity(0.2),
    ),
  ];

  final LatLng initialLocation = const LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // 🔵 Top Order Info Card
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: CupertinoColors.activeBlue,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID",
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "#LN2847",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.truck_fast,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Wash & Fold',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'In Transit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔘 Toggle Map / Timeline
            MapTimelineToggle(
              onChanged: (isMap) {
                setState(() {
                  showMap = isMap;
                });
              },
            ),

            const SizedBox(height: 20),

            // 📍 Map or Timeline with info below map
            SizedBox(
              // map + info height
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showMap
                    ? Column(
                        key: const ValueKey(1),
                        children: [
                          SizedBox(
                            height: 250,
                            child: GoogleMap(
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              initialCameraPosition: CameraPosition(
                                target: initialLocation,
                                zoom: 14.5,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              trafficEnabled: false,
                              compassEnabled: false,

                            ),
                          ),
                          const SizedBox(height: 10),
                          Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Delivery Information",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlueAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: const Text("Delivery Address"),
                                    subtitle: const Text("123 Main St, Apt 4B"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.timelapse_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: const Text("Estimated Delivery"),
                                    subtitle: const Text("Tomorrow, 10:00 AM"),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.purpleAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.storefront,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: const Text("Processing Store"),
                                    subtitle: const Text("Downtown Store"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey(2),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Timeline",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Build all timeline tiles
                          ...List.generate(
                            steps.length,
                            (index) => TimelineTile(
                              step: steps[index],
                              isFirst: index == 0,
                              isLast: index == steps.length - 1,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: SizedBox(
                              width:250,
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.delete_outline_rounded,color: Colors.red,),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  context.pop();
                                },
                                label: Text(
                                  "Cancel Order",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔘 Toggle Widget
class MapTimelineToggle extends StatefulWidget {
  final Function(bool isMap)? onChanged;

  const MapTimelineToggle({super.key, this.onChanged});

  @override
  State<MapTimelineToggle> createState() => _MapTimelineToggleState();
}

class _MapTimelineToggleState extends State<MapTimelineToggle> {
  bool isMapSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isMapSelected = true);
                widget.onChanged?.call(true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isMapSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: isMapSelected ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Live Map",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMapSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isMapSelected = false);
                widget.onChanged?.call(false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isMapSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timelapse_outlined,
                      color: !isMapSelected ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Timeline",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: !isMapSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineStep {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String? activeBadge;

  TimelineStep({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.activeBadge,
  });
}

class TimelineTile extends StatelessWidget {
  final TimelineStep step;
  final bool isFirst;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.step,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // Width of the left icon column
    const double iconColumnWidth = 60;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left icon and vertical line
          SizedBox(
            width: iconColumnWidth,
            child: Column(
              children: [
                // Icon container with shadow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: step.iconColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: step.iconColor.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 28),
                ),
                // Vertical line connecting steps
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.only(top: 5),
                      color: step.iconColor.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),

          // Right card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: step.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with optional active badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (step.activeBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            step.activeBadge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    step.description,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 10),

                  // Time with clock icon
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        step.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
