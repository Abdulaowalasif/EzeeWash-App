import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool showActiveOrders = true;

  // 👇 Active Orders Data
  final List<Map<String, dynamic>> activeOrders = [
    {
      "orderNo": "#EZ001",
      "service": "Wash & Fold",
      "store": "Downtown Store",
      "items": 8,
      "price": 100,
      "status": "Picked Up",
      "progress": 0.5,
      "timeline": [
        {"title": "Order Placed", "time": "10:30 AM", "done": true},
        {"title": "Picked Up", "time": "2:00 PM", "done": true},
        {"title": "In Process", "time": "Est. 4:00 PM", "done": false},
        {"title": "Ready for Delivery", "time": "Est. Tomorrow 10:00 AM", "done": false},
      ],
    },
    {
      "orderNo": "#EZ002",
      "service": "Dry Cleaning",
      "store": "Uptown Store",
      "items": 5,
      "price": 200,
      "status": "In Process",
      "progress": 0.3,
      "timeline": [
        {"title": "Order Placed", "time": "9:00 AM", "done": true},
        {"title": "Picked Up", "time": "11:00 AM", "done": true},
        {"title": "In Process", "time": "Est. 3:00 PM", "done": false},
        {"title": "Ready for Delivery", "time": "Est. Tomorrow 11:00 AM", "done": false},
      ],
    },
    {
      "orderNo": "#EZ003",
      "service": "Ironing",
      "store": "Midtown Store",
      "items": 12,
      "price": 150,
      "status": "Ready for Delivery",
      "progress": 0.8,
      "timeline": [
        {"title": "Order Placed", "time": "8:00 AM", "done": true},
        {"title": "Picked Up", "time": "10:00 AM", "done": true},
        {"title": "In Process", "time": "Est. 1:00 PM", "done": true},
        {"title": "Ready for Delivery", "time": "Est. Today 5:00 PM", "done": false},
      ],
    },
  ];

  // 👇 Completed Orders for History
  final List<Map<String, dynamic>> completedOrders = [
    {
      "orderNo": "#EZ101",
      "service": "Wash & Fold",
      "store": "Downtown Store",
      "items": 10,
      "price": 180,
      "status": "Delivered",
      "progress": 1.0,
      "timeline": [
        {"title": "Order Placed", "time": "9:00 AM", "done": true},
        {"title": "Picked Up", "time": "10:00 AM", "done": true},
        {"title": "In Process", "time": "12:00 PM", "done": true},
        {"title": "Delivered", "time": "2:00 PM", "done": true},
      ],
    },
    {
      "orderNo": "#EZ102",
      "service": "Dry Cleaning",
      "store": "Uptown Store",
      "items": 7,
      "price": 220,
      "status": "Delivered",
      "progress": 1.0,
      "timeline": [
        {"title": "Order Placed", "time": "8:30 AM", "done": true},
        {"title": "Picked Up", "time": "9:30 AM", "done": true},
        {"title": "In Process", "time": "11:00 AM", "done": true},
        {"title": "Delivered", "time": "1:00 PM", "done": true},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "My Orders",
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            OrdersToggle(
              isDark: isDark,
              onChanged: (isActive) {
                setState(() {
                  showActiveOrders = isActive;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: showActiveOrders ? activeOrders.length : completedOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final order = showActiveOrders ? activeOrders[index] : completedOrders[index];
                  return OrderCard(
                    orderNo: order["orderNo"],
                    service: order["service"],
                    store: order["store"],
                    items: order["items"],
                    price: order["price"],
                    status: order["status"],
                    progress: order["progress"],
                    timeline: order["timeline"],
                    isHistory: !showActiveOrders, // only history uses Reorder
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: primaryGradient,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push(RoutesName.placeOrdersNavigate),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class OrdersToggle extends StatefulWidget {
  final Function(bool isActiveOrders)? onChanged;
  final bool isDark;

  const OrdersToggle({super.key, this.onChanged, required this.isDark});

  @override
  State<OrdersToggle> createState() => _OrdersToggleState();
}

class _OrdersToggleState extends State<OrdersToggle> {
  bool isActiveOrders = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isActiveOrders = true);
                widget.onChanged?.call(true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isActiveOrders ? primaryGradient : null,
                  color: isActiveOrders ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActiveOrders
                      ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Active Orders",
                    style: GoogleFonts.alexandria(
                      fontWeight: isActiveOrders ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isActiveOrders ? Colors.white : (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isActiveOrders = false);
                widget.onChanged?.call(false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !isActiveOrders ? primaryGradient : null,
                  color: !isActiveOrders ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isActiveOrders
                      ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    "Order History",
                    style: GoogleFonts.alexandria(
                      fontWeight: !isActiveOrders ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: !isActiveOrders ? Colors.white : (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatefulWidget {
  final String? orderNo;
  final String? service;
  final String? store;
  final int? items;
  final int? price;
  final String? status;
  final double? progress;
  final List<Map<String, dynamic>>? timeline;
  final bool isHistory;
  final bool isDark;

  const OrderCard({
    super.key,
    this.orderNo,
    this.service,
    this.store,
    this.items,
    this.price,
    this.status,
    this.progress,
    this.timeline,
    this.isHistory = false,
    required this.isDark,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: widget.isDark ? Border.all(color: Colors.white12) : Border.all(color: Colors.grey.shade100),
        boxShadow: widget.isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP CONTENT
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.orderNo ?? "#EZ001",
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.service ?? "Wash & Fold",
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        color: widget.isDark ? Colors.grey.shade300 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.store ?? "Downtown Store",
                      style: GoogleFonts.alexandria(
                        fontSize: 11,
                        color: widget.isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status ?? "Picked Up",
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "৳ ${widget.price ?? 100}",
                    style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${widget.items ?? 8} items",
                style: GoogleFonts.alexandria(fontSize: 13, color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              Text(
                "Delivery: 2026-01-16",
                style: GoogleFonts.alexandria(fontSize: 12, color: widget.isDark ? Colors.grey.shade500 : Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom Gradient Progress Bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white12 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * (widget.progress ?? 0.5),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.remove_red_eye_outlined,
                    color: primaryColor,
                    size: 18,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                  label: Text(
                    isExpanded ? "Hide Details" : "View Details",
                    style: GoogleFonts.alexandria(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: widget.isHistory
                        ? const Icon(Icons.replay_outlined, color: Colors.white, size: 18)
                        : const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (widget.isHistory) {
                        context.push(RoutesName.placeOrdersNavigate); // Reorder
                      } else {
                        context.push(RoutesName.trackOrdersNavigate); // Active Track Order
                      }
                    },
                    label: Text(
                      widget.isHistory ? "Reorder" : "Track Order",
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // TIMELINE
          if (isExpanded && widget.timeline != null) ...[
            const SizedBox(height: 20),
            Divider(color: widget.isDark ? Colors.white12 : Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              "Order Timeline",
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...widget.timeline!.map((step) {
              final done = step["done"] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? primaryColor.withOpacity(0.15) : (widget.isDark ? Colors.white12 : Colors.grey.shade100),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        done ? Icons.check_circle : Icons.circle_outlined,
                        color: done ? primaryColor : Colors.grey.shade400,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step["title"],
                            style: GoogleFonts.alexandria(
                              fontWeight: done ? FontWeight.bold : FontWeight.w500,
                              color: done ? (widget.isDark ? Colors.white : Colors.black87) : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step["time"],
                            style: GoogleFonts.alexandria(
                              color: done ? (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600) : Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ]
        ],
      ),
    );
  }
}