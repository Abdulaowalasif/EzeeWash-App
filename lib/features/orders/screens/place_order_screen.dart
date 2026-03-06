import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int currentStep = 1;

  int? selectedServiceIndex;
  int? selectedStoreIndex;

  DateTime? pickupDate;
  String pickupTime = 'Select time';
  DateTime? deliveryDate;
  String deliveryTime = 'Select time';

  final TextEditingController addressController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();

  final List<Map<String, dynamic>> services = [
    {
      "title": "Wash & Fold",
      "subtitle": "Professional washing and folding service",
      "icon": Icons.water_drop_outlined,
      "price": 12.99,
      "duration": "24-48 hrs"
    },
    {
      "title": "Dry & Clean",
      "subtitle": "Expert dry cleaning for delicate items",
      "icon": Icons.dry_cleaning,
      "price": 18.99,
      "duration": "48-72 hrs"
    },
    {
      "title": "Iron & Press",
      "subtitle": "Perfect pressing and ironing",
      "icon": Icons.local_fire_department_outlined,
      "price": 8.99,
      "duration": "24 hrs"
    },
    {
      "title": "Express Service",
      "subtitle": "Same day pickup and delivery",
      "icon": Icons.flash_on,
      "price": 24.99,
      "duration": "12 hrs"
    },
  ];

  final List<Map<String, dynamic>> stores = [
    {
      'name': "Downtown Store",
      'address': '123 Main St, Dhaka',
      'distance': '0.5 km',
      'icon': Icons.storefront_outlined,
    },
    {
      'name': "Shopping Mall",
      'address': '456 Market St, Dhaka',
      'distance': '1.2 km',
      'icon': Icons.storefront_outlined,
    },
    {
      'name': "Suburb Branch",
      'address': '789 Sunset Blvd, Dhaka',
      'distance': '2.5 km',
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
      return addressController.text.trim().isNotEmpty &&
          instructionsController.text.trim().isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Book Service",
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                StepProgressCard(currentStep: currentStep, isDark: isDark),
                const SizedBox(height: 24),

                // Dynamic Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStepTitle(),
                        style: GoogleFonts.alexandria(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStepSubtitle(),
                        style: GoogleFonts.alexandria(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Animated Body Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildStepContent(isDark),
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 30),
                  color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: currentStep == 1 ? context.pop : previousStep,
                          child: Text(
                            currentStep == 1 ? "Cancel" : "Back",
                            style: GoogleFonts.alexandria(
                              color: isDark ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: isNextEnabled() ? primaryGradient : null,
                            color: isNextEnabled() ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isNextEnabled()
                                ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              style: GoogleFonts.alexandria(
                                color: isNextEnabled() ? Colors.white : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case 1: return "Select Service";
      case 2: return "Select Store";
      case 3: return "Schedule Service";
      case 4: return "Final Details";
      default: return "";
    }
  }

  String _getStepSubtitle() {
    switch (currentStep) {
      case 1: return "Choose the service that best fits your needs";
      case 2: return "Select a nearby store location";
      case 3: return "Choose your pickup and delivery times";
      case 4: return "Review your order and add instructions";
      default: return "";
    }
  }

  Widget _buildStepContent(bool isDark) {
    if (currentStep == 1) {
      return Column(
        key: const ValueKey(1),
        children: List.generate(services.length, (index) {
          final service = services[index];
          return ServiceCard(
            title: service["title"],
            subtitle: service["subtitle"],
            price: "৳${service["price"]}",
            duration: service["duration"],
            icon: service["icon"],
            isSelected: selectedServiceIndex == index,
            isDark: isDark,
            onTap: () => setState(() => selectedServiceIndex = index),
          );
        }),
      );
    } else if (currentStep == 2) {
      return Column(
        key: const ValueKey(2),
        children: List.generate(stores.length, (index) {
          final store = stores[index];
          return StoreCard(
            name: store["name"],
            address: store["address"],
            distance: store["distance"],
            icon: store["icon"],
            isSelected: selectedStoreIndex == index,
            isDark: isDark,
            onTap: () => setState(() => selectedStoreIndex = index),
          );
        }),
      );
    } else if (currentStep == 3) {
      return Container(
        key: const ValueKey(3),
        child: ScheduleForm(
          pickupDate: pickupDate,
          onPickupDateChanged: (date) => setState(() => pickupDate = date),
          pickupTime: pickupTime,
          onPickupTimeChanged: (time) => setState(() => pickupTime = time),
          deliveryDate: deliveryDate,
          onDeliveryDateChanged: (date) => setState(() => deliveryDate = date),
          deliveryTime: deliveryTime,
          onDeliveryTimeChanged: (time) => setState(() => deliveryTime = time),
          isDark: isDark,
        ),
      );
    } else {
      // Dynamic Data Passed to Step 4
      final selectedService = services[selectedServiceIndex!];
      final selectedStore = stores[selectedStoreIndex!];

      return Container(
        key: const ValueKey(4),
        child: AddressDetails(
          addressController: addressController,
          instructionController: instructionsController,
          selectedService: selectedService,
          selectedStore: selectedStore,
          pickupDate: pickupDate!,
          pickupTime: pickupTime,
          deliveryDate: deliveryDate!,
          deliveryTime: deliveryTime,
          isDark: isDark,
        ),
      );
    }
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
  final bool isDark;

  ScheduleForm({
    super.key,
    required this.pickupDate,
    required this.onPickupDateChanged,
    required this.pickupTime,
    required this.onPickupTimeChanged,
    required this.deliveryDate,
    required this.onDeliveryDateChanged,
    required this.deliveryTime,
    required this.onDeliveryTimeChanged,
    required this.isDark,
  });

  final List<String> timeOptions = ['Select time', '10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM'];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  InputDecoration _inputDeco(String label, String hint, bool isDark) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleCard(
          title: 'Pickup Schedule',
          icon: Icons.upload_rounded,
          iconColor: primaryColor,
          gradient: primaryGradient,
          date: pickupDate,
          time: pickupTime,
          onDateChanged: onPickupDateChanged,
          onTimeChanged: onPickupTimeChanged,
          context: context,
        ),
        const SizedBox(height: 24),
        _buildScheduleCard(
          title: 'Delivery Schedule',
          icon: Icons.download_rounded,
          iconColor: const Color(0xFF10B981),
          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          date: deliveryDate,
          time: deliveryTime,
          onDateChanged: onDeliveryDateChanged,
          onTimeChanged: onDeliveryTimeChanged,
          context: context,
        ),
      ],
    );
  }

  Widget _buildScheduleCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Gradient gradient,
    required DateTime? date,
    required String time,
    required ValueChanged<DateTime> onDateChanged,
    required ValueChanged<String> onTimeChanged,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: TextEditingController(text: _formatDate(date)),
            decoration: _inputDeco('Date', 'dd/mm/yyyy', isDark).copyWith(
              suffixIcon: IconButton(
                icon: Icon(Icons.calendar_today_rounded, color: iconColor),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: iconColor)),
                      child: child!,
                    ),
                  );
                  if (picked != null) onDateChanged(picked);
                },
              ),
            ),
            readOnly: true,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: time,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: _inputDeco('Time', '', isDark),
            items: timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (newTime) {
              if (newTime != null) onTimeChanged(newTime);
            },
          ),
        ],
      ),
    );
  }
}

class AddressDetails extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController instructionController;
  final Map<String, dynamic> selectedService;
  final Map<String, dynamic> selectedStore;
  final DateTime pickupDate;
  final String pickupTime;
  final DateTime deliveryDate;
  final String deliveryTime;
  final bool isDark;

  const AddressDetails({
    super.key,
    required this.addressController,
    required this.instructionController,
    required this.selectedService,
    required this.selectedStore,
    required this.pickupDate,
    required this.pickupTime,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.isDark,
  });

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.alexandria(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, size: 22),
      filled: true,
      fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pickup/Delivery Address", style: GoogleFonts.alexandria(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: _inputDeco("Enter your complete address", Icons.location_on_outlined),
              ),
              const SizedBox(height: 24),
              Text("Special Instructions", style: GoogleFonts.alexandria(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              TextField(
                controller: instructionController,
                maxLines: 3,
                decoration: _inputDeco("Any special instructions...", Icons.note_alt_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark ? null : LinearGradient(colors: [primaryColor.withOpacity(0.05), primaryColor.withOpacity(0.01)]),
            color: isDark ? const Color(0xFF1A1A2E) : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: primaryColor),
                  const SizedBox(width: 8),
                  Text("Order Summary", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 16),
              _summaryRow("Service:", selectedService['title'], isDark),
              const SizedBox(height: 10),
              _summaryRow("Store:", selectedStore['name'], isDark),
              const SizedBox(height: 10),
              _summaryRow("Pickup:", "${_formatDate(pickupDate)} at $pickupTime", isDark),
              const SizedBox(height: 10),
              _summaryRow("Delivery:", "${_formatDate(deliveryDate)} at $deliveryTime", isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: isDark ? Colors.white24 : primaryColor.withOpacity(0.2), thickness: 1.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total:", style: GoogleFonts.alexandria(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("৳${selectedService['price']}", style: GoogleFonts.alexandria(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.alexandria(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14)),
        Text(value, style: GoogleFonts.alexandria(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

// StoreCard and ServiceCard remain mostly unchanged but visually harmonize perfectly
class StoreCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  const StoreCard({super.key, required this.name, required this.address, required this.distance, required this.icon, required this.isSelected, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.08)) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.grey.shade200), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6))] : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(gradient: isSelected ? primaryGradient : null, color: isSelected ? null : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade500), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address, style: GoogleFonts.alexandria(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Text(distance, style: GoogleFonts.alexandria(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: primaryGradient), child: const Icon(Icons.check, color: Colors.white, size: 18)),
          ],
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
  final bool isDark;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.title, required this.subtitle, required this.price, required this.duration, required this.icon, this.isSelected = false, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? primaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.08)) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.grey.shade200), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6))] : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        ),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(gradient: isSelected ? primaryGradient : null, color: isSelected ? null : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade500), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.alexandria(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(price, style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(duration, style: GoogleFonts.alexandria(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: primaryGradient), child: const Icon(Icons.check, color: Colors.white, size: 18)),
          ],
        ),
      ),
    );
  }
}

class StepProgressCard extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const StepProgressCard({super.key, required this.currentStep, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white12) : null,
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
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
    );
  }

  Widget _buildStep(int step) {
    bool isCompleted = step < currentStep;
    bool isActive = step == currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: (isCompleted || isActive) ? primaryGradient : null,
        color: (isCompleted || isActive) ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text("$step", style: GoogleFonts.alexandria(color: isActive ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildLine(int step) {
    bool isCompleted = step < currentStep;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3, margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: isCompleted ? primaryGradient : null,
          color: isCompleted ? null : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}