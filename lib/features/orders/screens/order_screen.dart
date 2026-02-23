import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool showActiveOrders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Text(
          "My Orders",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            OrdersToggle(
              onChanged: (isActive) {
                setState(() {
                  showActiveOrders = isActive;
                });
              },
            ),

            const SizedBox(height: 20),

            /// 👇 THIS is what makes it show
            if (showActiveOrders)
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) => const OrderCard(),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: 2,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) => const OrderCard(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutesName.placeOrdersNavigate),
        shape: const StadiumBorder(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Iconsax.add, color: Colors.white, size: 30),
      ),
    );
  }
}

//order toggle class
class OrdersToggle extends StatefulWidget {
  final Function(bool isActiveOrders)? onChanged;

  const OrdersToggle({super.key, this.onChanged});

  @override
  State<OrdersToggle> createState() => _OrdersToggleState();
}

class _OrdersToggleState extends State<OrdersToggle> {
  bool isActiveOrders = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          /// Active Orders
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isActiveOrders = true);
                widget.onChanged?.call(true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActiveOrders ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Active Orders (2)",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isActiveOrders
                          ? CupertinoColors.activeBlue
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// Order History
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isActiveOrders = false);
                widget.onChanged?.call(false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isActiveOrders ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Order History (3)",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: !isActiveOrders
                          ? CupertinoColors.activeBlue
                          : Colors.black87,
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
  const OrderCard({super.key});

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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP CONTENT (Always Visible)
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("#EZ001"),
                  Text("Wash & Fold"),
                  Text("Downtown Store"),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text("Picked Up"),
                  ),
                  Text("৳ 100"),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text("8 items"), Text("Delivery: 2026-01-16")],
          ),

          const SizedBox(height: 10),

          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: const Text("50%"),
          ),

          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(10),
            minHeight: 5,
            value: 0.5,
            backgroundColor: Colors.grey.withOpacity(0.3),
            color: Colors.blue,
          ),

          const SizedBox(height: 10),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.remove_red_eye_outlined,
                    color: Colors.blue,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  label: Text(
                    isExpanded ? "Hide Details" : "View Details",
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    context.push(RoutesName.trackOrdersNavigate);
                  },
                  label: const Text(
                    "Track Order",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          /// 👇 EXPANDABLE SECTION
          if (isExpanded) ...[
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              "Order Timeline",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            ListTile(
              minTileHeight: 50,
              contentPadding: EdgeInsets.all(0),
              leading: Icon(Icons.circle, color: Colors.blue),
              trailing: Icon(Icons.done, color: Colors.blue),
              title: Text('Order Placed'),
              subtitle: Text("10:30 AM"),
            ),
            ListTile(
              minTileHeight: 50,
              contentPadding: EdgeInsets.all(0),
              leading: Icon(Icons.circle, color: Colors.blue),
              trailing: Icon(Icons.done, color: Colors.blue),
              title: Text('Picked Up'),
              subtitle: Text("2:00 PM"),
            ),
            ListTile(
              minTileHeight: 50,
              contentPadding: EdgeInsets.all(0),
              leading: Icon(Icons.circle, color: Colors.grey),
              title: Text('In Process', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                "Est. 4:00 PM",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListTile(
              minTileHeight: 50,
              contentPadding: EdgeInsets.all(0),
              leading: Icon(Icons.circle, color: Colors.grey),
              title: Text(
                'Ready for Delivery',
                style: TextStyle(color: Colors.grey),
              ),
              subtitle: Text(
                "Est. Tomorrow 10:00 AM",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
