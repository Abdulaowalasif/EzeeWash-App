import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              onChanged: (index) {
                if (index == 0) {
                  // Show Active Orders
                } else {
                  // Show Order History
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {},
      shape: StadiumBorder(),
        backgroundColor: Colors.blueAccent,
        child: Icon(Iconsax.add,color: Colors.white,size: 30,fontWeight: FontWeight.bold,),
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
