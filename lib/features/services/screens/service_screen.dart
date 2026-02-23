import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  int selectedIndex = 0;

  final images = [
    'assets/service_picture/comfort_clean.jpg',
    'assets/service_picture/delicate_care.jpg',
    'assets/service_picture/dry_clean.jpg',
    'assets/service_picture/express.png',
    'assets/service_picture/iron_&_press.jpg',
    'assets/service_picture/steam_clean.jpg',
    'assets/service_picture/suit_wash.jpg',
    'assets/service_picture/wash_&_fold.jpg',
  ];

  final services = [
    {'icon': Iconsax.category, 'category': 'All Services'},
    {'icon': Icons.water_drop_outlined, 'category': 'Wash & Fold'},
    {'icon': Icons.dry_cleaning_outlined, 'category': 'Dry Clean'},
    {'icon': Icons.local_fire_department_outlined, 'category': 'Iron & Press'},
    {'icon': Icons.flash_on, 'category': 'Express'},
  ];

  // Filter images based on selected category
  List<String> filteredImages() {
    switch (selectedIndex) {
      case 0: // All Services
        return images;
      case 1: // Wash & Fold
        return [
          'assets/service_picture/wash_&_fold.jpg',
          'assets/service_picture/comfort_clean.jpg'
        ];
      case 2: // Dry Clean
        return [
          'assets/service_picture/dry_clean.jpg',
          'assets/service_picture/delicate_care.jpg'
        ];
      case 3: // Iron & Press
        return ['assets/service_picture/iron_&_press.jpg'];
      case 4: // Express
        return ['assets/service_picture/express.png'];
      default:
        return images;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "Our Services",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(services.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: ServiceCategoryCard(
                        isSelected: selectedIndex == index,
                        category: services[index]['category']! as String,
                        icon: services[index]['icon']! as IconData,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: filteredImages().length,
                itemBuilder: (context, index) =>
                    ServiceCard(service: filteredImages()[index]),
                separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCategoryCard extends StatelessWidget {
  final bool isSelected;
  final String category;
  final IconData icon;

  const ServiceCategoryCard({
    super.key,
    required this.isSelected,
    required this.category,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey, width: 1),
        color: isSelected ? Colors.blue : Colors.transparent,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 10),
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String service;

  const ServiceCard({super.key, required this.service});

  // Helper for tags
  Widget tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.lightBlueAccent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: GoogleFonts.poppins(color: Colors.deepPurple)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Image.asset(service),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LEFT SIDE (title + description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Regular Wash & Fold",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Standard wash and fold service for everyday clothes",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// RIGHT SIDE (price + time)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "৳ 30",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text("24–48 hours", style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              Icon(Icons.star, color: Colors.amber, size: 18),
              Icon(Icons.star, color: Colors.amber, size: 18),
              Icon(Icons.star, color: Colors.amber, size: 18),
              Icon(Icons.star_border, color: Colors.amber, size: 18),
              const SizedBox(width: 10),
              Text(
                "4.8",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "(156 reviews)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// TAGS
          Wrap(
            spacing: 10,
            children: [
              tag("Wash"),
              tag("Dry"),
              tag("Fold"),
              tag("Fabric Softener"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.star_border, color: Colors.blueAccent),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  label: Text(
                    "Review",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push(RoutesName.placeOrdersNavigate),
                  label: Text(
                    "Book Now",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}