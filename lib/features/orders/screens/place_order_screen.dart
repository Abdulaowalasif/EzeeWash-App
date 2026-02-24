import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int currentStep = 1;

  int? selectedServiceIndex;
  int? selectedStoreIndex;

  // Step 3: lifted state
  DateTime? pickupDate;
  String pickupTime = 'Select time';
  DateTime? deliveryDate;
  String deliveryTime = 'Select time';
  final TextEditingController addressController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  final services = [
    {
      "title": "Wash & Fold",
      "subtitle": "Professional washing and folding service",
      "icon": Icons.water_drop_outlined,
    },
    {
      "title": "Dry & Clean",
      "subtitle": "Expert dry cleaning for delicate items",
      "icon": Icons.dry_cleaning,
    },
    {
      "title": "Iron & Press",
      "subtitle": "Perfect pressing and ironing",
      "icon": Icons.local_fire_department_outlined,
    },
    {
      "title": "Express Service",
      "subtitle": "Same day pickup and delivery",
      "icon": Icons.flash_on,
    },
  ];

  final stores = [
    {
      'name': "Downtown Store",
      'address': '123 Main St',
      'distance': '0.5 km',
      'icon': Icons.storefront_outlined,
    },
    {
      'name': "Shopping Mall",
      'address': '456 Market St',
      'distance': '1.2 km',
      'icon': Icons.storefront_outlined,
    },
    {
      'name': "Suburb Branch",
      'address': '789 Sunset Blvd',
      'distance': '2.5 km',
      'icon': Icons.storefront_outlined,
    },
    {
      'name': "Main Company",
      'address': '101 Business Ave',
      'distance': '3.1 km',
      'icon': Icons.storefront_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    addressController.addListener(() => setState(() {}));
    instructionsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    addressController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep < 4) {
      setState(() => currentStep++);
    }
  }

  void previousStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    }
  }

  bool isNextEnabled() {
    if (currentStep == 1) return selectedServiceIndex != null;
    if (currentStep == 2) return selectedStoreIndex != null;
    if (currentStep == 3) {
      return pickupDate != null &&
          deliveryDate != null &&
          pickupTime != 'Select time' &&
          deliveryTime != 'Select time';
    }
    if (currentStep == 4) {
      // Enable only if both fields are filled
      return addressController.text.trim().isNotEmpty &&
          instructionsController.text.trim().isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Service")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              StepProgressCard(currentStep: currentStep),
              const SizedBox(height: 20),

              /// Dynamic Title
              Text(
                currentStep == 1
                    ? "Select Service"
                    : currentStep == 2
                    ? "Select Store"
                    : currentStep == 3
                    ? "Schedule Service"
                    : "Final Details",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentStep == 1
                    ? "Choose the service that best fits your needs"
                    : currentStep == 2
                    ? "Select a nearby store"
                    : currentStep == 3
                    ? "Choose your pickup and delivery times"
                    : "Add your address and special instructions",
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 20),

              /// STEP 1 - SERVICES
              if (currentStep == 1)
                ...List.generate(services.length, (index) {
                  final service = services[index];
                  return ServiceCard(
                    title: service["title"] as String,
                    subtitle: service["subtitle"] as String,
                    price: "৳12.99",
                    duration: "24-48 hours",
                    icon: service["icon"] as IconData,
                    isSelected: selectedServiceIndex == index,
                    onTap: () {
                      setState(() {
                        selectedServiceIndex = index;
                      });
                    },
                  );
                }),

              /// STEP 2 - STORES
              if (currentStep == 2)
                ...List.generate(stores.length, (index) {
                  final store = stores[index];
                  return StoreCard(
                    name: store["name"] as String,
                    address: store["address"] as String,
                    distance: store["distance"] as String,
                    icon: store["icon"] as IconData,
                    isSelected: selectedStoreIndex == index,
                    onTap: () {
                      setState(() {
                        selectedStoreIndex = index;
                      });
                    },
                  );
                }),

              /// STEP 3 - SCHEDULE
              if (currentStep == 3)
                ScheduleForm(
                  pickupDate: pickupDate,
                  onPickupDateChanged: (date) =>
                      setState(() => pickupDate = date),
                  pickupTime: pickupTime,
                  onPickupTimeChanged: (time) =>
                      setState(() => pickupTime = time),
                  deliveryDate: deliveryDate,
                  onDeliveryDateChanged: (date) =>
                      setState(() => deliveryDate = date),
                  deliveryTime: deliveryTime,
                  onDeliveryTimeChanged: (time) =>
                      setState(() => deliveryTime = time),
                ),

              if (currentStep == 4)
                AddressDetails(
                  addressController: addressController,
                  instructionController: instructionsController,
                ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: currentStep == 1 ? context.pop : previousStep,
                      child: Text(
                        currentStep == 1 ? "Cancel" : "Back",
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isNextEnabled()
                            ? Colors.blue
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (isNextEnabled())
                          ? () {
                              if (currentStep == 4) {
                                context.push(RoutesName.confirmedOrdersNavigate);
                              } else {
                                nextStep();
                              }
                            }
                          : null,
                      child: Text(
                        currentStep == 4 ? "Confirm Booking" : "Next",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleForm extends StatelessWidget {
  final DateTime? pickupDate;
  final ValueChanged<DateTime> onPickupDateChanged;
  final String pickupTime;
  final ValueChanged<String> onPickupTimeChanged;

  final DateTime? deliveryDate;
  final ValueChanged<DateTime> onDeliveryDateChanged;
  final String deliveryTime;
  final ValueChanged<String> onDeliveryTimeChanged;

  ScheduleForm({
    required this.pickupDate,
    required this.onPickupDateChanged,
    required this.pickupTime,
    required this.onPickupTimeChanged,
    required this.deliveryDate,
    required this.onDeliveryDateChanged,
    required this.deliveryTime,
    required this.onDeliveryTimeChanged,
  });

  final List<String> timeOptions = [
    'Select time',
    '10:00 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
  ];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.upload, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Pickup Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: TextEditingController(
                  text: _formatDate(pickupDate),
                ),
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'mm/dd/yyyy',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: pickupDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) onPickupDateChanged(picked);
                    },
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: pickupTime,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                ),
                items: timeOptions
                    .map(
                      (time) =>
                          DropdownMenuItem(value: time, child: Text(time)),
                    )
                    .toList(),
                onChanged: (newTime) {
                  if (newTime != null) onPickupTimeChanged(newTime);
                },
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Delivery Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.download, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Delivery Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: TextEditingController(
                  text: _formatDate(deliveryDate),
                ),
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'mm/dd/yyyy',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: deliveryDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) onDeliveryDateChanged(picked);
                    },
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: deliveryTime,
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                ),
                items: timeOptions
                    .map(
                      (time) =>
                          DropdownMenuItem(value: time, child: Text(time)),
                    )
                    .toList(),
                onChanged: (newTime) {
                  if (newTime != null) onDeliveryTimeChanged(newTime);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StoreCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2F6BFF);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? blue.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? blue : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: blue.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            /// Left Icon Box (same style as ServiceCard)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            /// Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  /// Distance Chip (same style as duration chip)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      distance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Check Icon
            if (isSelected)
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class StepProgressCard extends StatelessWidget {
  final int currentStep; // 1-based index

  const StepProgressCard({Key? key, required this.currentStep})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(4 * 2 - 1, (index) {
            if (index.isEven) {
              int stepNumber = (index ~/ 2) + 1;
              return _buildStep(stepNumber);
            } else {
              int lineIndex = (index ~/ 2) + 1;
              return _buildLine(lineIndex);
            }
          }),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    bool isCompleted = step < currentStep;
    bool isActive = step == currentStep;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? Colors.blue : Colors.grey.shade300,
        borderRadius: BorderRadiusGeometry.circular(15),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white)
            : Text(
                "$step",
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildLine(int step) {
    bool isCompleted = step < currentStep;

    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String duration;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.duration,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2F6BFF);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? blue.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? blue : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: blue.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Left Icon Box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Check Icon
            if (isSelected)
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class AddressDetails extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController instructionController;

  const AddressDetails({
    super.key,
    required this.addressController,
    required this.instructionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsetsGeometry.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pickup/Delivery Address", style: GoogleFonts.poppins()),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  hint: Text(
                    "Enter your complete address",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: EdgeInsetsGeometry.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Special Instructions", style: GoogleFonts.poppins()),
              const SizedBox(height: 10),
              TextField(
                controller: instructionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hint: Text(
                    "Any special instructions for pickup or delivery...",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: EdgeInsetsGeometry.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 0.5),
          ),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order Summery",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Service:",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  Text(
                    "Dry Clean",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Store:",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  Text(
                    "Suburb Branch",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pickup:",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  Text(
                    "2026-02-06 at 9:00 AM",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Delivery:",
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  Text(
                    "2026-02-10 at 9:00 AM",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.blue),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total:",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "৳18.99",
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
