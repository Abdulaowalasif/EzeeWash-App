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

  // Sample reviews
  final List<Map<String, dynamic>> reviews = const [
    {"reviewer": "Alice", "comment": "Excellent service!", "rating": 5.0},
    {"reviewer": "Bob", "comment": "Very quick and neat.", "rating": 4.5},
    {"reviewer": "Charlie", "comment": "Satisfied with the fold quality.", "rating": 4.0},
  ];

  void _showReviewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Reviews",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SizedBox(
                  height: 250,
                  child: ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final r = reviews[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text(
                            r["reviewer"][0],
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                        title: Text(
                          r["reviewer"],
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < r["rating"].floor()
                                      ? Iconsax.star1
                                      : Iconsax.star,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r["comment"],
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper for tags
  Widget tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blueAccent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.blueAccent,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Service Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              service,
              fit: BoxFit.cover,
              height: 140,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 20),

          // Title & Description + Price & Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Regular Wash & Fold",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Standard wash and fold service for everyday clothes",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // RIGHT: Price + Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "৳ 30",
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  Text(
                    "24–48 hours",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tags
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                tag("Wash"),
                tag("Dry"),
                tag("Fold"),
                tag("Fabric Softener"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon:
                  const Icon(Iconsax.star, color: Colors.blueAccent, size: 18),
                  onPressed: () => _showReviewsSheet(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: Text(
                    "Review",
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.calendar, color: Colors.white, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    context.push(RoutesName.placeOrdersNavigate);
                  },
                  label: Text(
                    "Book Now",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w500),
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