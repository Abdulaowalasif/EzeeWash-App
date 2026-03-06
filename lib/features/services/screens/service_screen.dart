import 'dart:math';
import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const primaryBrandColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class Service {
  final String category;
  final String image;
  final String title;
  final String description;
  final String price;
  final String duration;
  final List<String> tags;

  Service({
    required this.category,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.tags,
  });
}

class _ServiceScreenState extends State<ServiceScreen> {
  int selectedIndex = 0;
  String searchQuery = "";

  // =================== Services Data ===================
  final List<Service> allServices = [
    Service(
      category: "Wash & Fold",
      image: 'assets/service_picture/wash_&_fold.jpg',
      title: "Regular Wash & Fold",
      description: "Standard wash and fold service for everyday clothes",
      price: "৳ 30",
      duration: "24–48 hours",
      tags: ["Wash", "Dry", "Fold", "Fabric Softener"],
    ),
    Service(
      category: "Wash & Fold",
      image: 'assets/service_picture/comfort_clean.jpg',
      title: "Comfort Clean Wash",
      description: "Gentle wash for delicate everyday fabrics",
      price: "৳ 40",
      duration: "24–48 hours",
      tags: ["Comfort", "Fold", "Softener"],
    ),
    Service(
      category: "Dry Clean",
      image: 'assets/service_picture/dry_clean.jpg',
      title: "Dry Clean Standard",
      description: "Professional dry cleaning for your garments",
      price: "৳ 100",
      duration: "48–72 hours",
      tags: ["Dry", "Press", "Delicate Care"],
    ),
    Service(
      category: "Dry Clean",
      image: 'assets/service_picture/delicate_care.jpg',
      title: "Delicate Care",
      description: "Special dry cleaning for delicate fabrics",
      price: "৳ 120",
      duration: "48–72 hours",
      tags: ["Delicate", "Care", "Press"],
    ),
    Service(
      category: "Iron & Press",
      image: 'assets/service_picture/iron_&_press.jpg',
      title: "Iron & Press",
      description: "Professional ironing and pressing service",
      price: "৳ 50",
      duration: "24–48 hours",
      tags: ["Iron", "Press"],
    ),
    Service(
      category: "Express",
      image: 'assets/service_picture/express.png',
      title: "Express Service",
      description: "Quick wash & fold within 12 hours",
      price: "৳ 60",
      duration: "12–24 hours",
      tags: ["Quick", "Wash", "Fold"],
    ),
    Service(
      category: "Steam Clean",
      image: 'assets/service_picture/steam_clean.jpg',
      title: "Steam Clean",
      description: "Steam cleaning for clothes & soft fabrics",
      price: "৳ 80",
      duration: "24–48 hours",
      tags: ["Steam", "Clean", "Refresh"],
    ),
    Service(
      category: "Suit Wash",
      image: 'assets/service_picture/suit_wash.jpg',
      title: "Suit Wash",
      description: "Specialized washing for formal suits",
      price: "৳ 150",
      duration: "48–72 hours",
      tags: ["Suit", "Wash", "Press"],
    ),
  ];

  final categories = [
    {'icon': Iconsax.category, 'category': 'All Services'},
    {'icon': Icons.water_drop_outlined, 'category': 'Wash & Fold'},
    {'icon': Icons.dry_cleaning_outlined, 'category': 'Dry Clean'},
    {'icon': Icons.local_fire_department_outlined, 'category': 'Iron & Press'},
    {'icon': Icons.flash_on, 'category': 'Express'},
  ];

  List<Service> filteredServices() {
    var services = selectedIndex == 0
        ? allServices
        : allServices
        .where((s) => s.category == categories[selectedIndex]['category'])
        .toList();

    if (searchQuery.isNotEmpty) {
      services = services
          .where((s) =>
          s.title.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return services;
  }

  // Random reviews generator
  final List<Map<String, dynamic>> sampleReviews = [
    {"reviewer": "Alice", "comment": "Excellent service!", "rating": 5.0},
    {"reviewer": "Bob", "comment": "Very quick and neat.", "rating": 4.5},
    {"reviewer": "Charlie", "comment": "Satisfied with the fold quality.", "rating": 4.0},
    {"reviewer": "David", "comment": "Good, but can improve.", "rating": 3.5},
    {"reviewer": "Emma", "comment": "Highly recommended!", "rating": 5.0},
    {"reviewer": "Fiona", "comment": "Decent service.", "rating": 4.0},
    {"reviewer": "George", "comment": "Loved it!", "rating": 4.8},
  ];

  List<Map<String, dynamic>> getRandomReviews() {
    final rnd = Random();
    final count = rnd.nextInt(3) + 2; // 2-4 reviews
    sampleReviews.shuffle(rnd);
    return sampleReviews.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // Responsive constraint for tablets
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 24),

                  // ================= Search Box =================
                  if (selectedIndex == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: isDark
                              ? []
                              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search services...",
                            hintStyle: GoogleFonts.alexandria(color: Colors.grey.shade500, fontSize: 14),
                            prefixIcon: Icon(Iconsax.search_normal, color: Colors.grey.shade400, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryBrandColor)),
                          ),
                        ),
                      ),
                    ),

                  // ================= Category Tabs =================
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(categories.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                                searchQuery = "";
                              });
                            },
                            child: ServiceCategoryCard(
                              isSelected: selectedIndex == index,
                              category: categories[index]['category']! as String,
                              icon: categories[index]['icon']! as IconData,
                              isDark: isDark,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ================= Service Cards =================
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredServices().length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final service = filteredServices()[index];
                      return ServiceCard(
                        service: service,
                        reviews: getRandomReviews(),
                        isDark: isDark,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= Top AppBar =================
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBrandColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Our Services",
            style: GoogleFonts.alexandria(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Iconsax.category, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }
}

/// ================= Service Category Card =================
class ServiceCategoryCard extends StatelessWidget {
  final bool isSelected;
  final String category;
  final IconData icon;
  final bool isDark;

  const ServiceCategoryCard({
    super.key,
    required this.isSelected,
    required this.category,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1.2),
        gradient: isSelected ? primaryGradient : null,
        color: isSelected ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        boxShadow: isSelected
            ? [BoxShadow(color: primaryBrandColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          const SizedBox(width: 8),
          Text(
            category,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= Service Card =================
class ServiceCard extends StatelessWidget {
  final Service service;
  final List<Map<String, dynamic>> reviews;
  final bool isDark;

  const ServiceCard({
    super.key,
    required this.service,
    required this.reviews,
    required this.isDark,
  });

  void _showReviewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Text(
                "Customer Reviews",
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final r = reviews[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: primaryBrandColor.withOpacity(0.15),
                            child: Text(
                              r["reviewer"][0],
                              style: const TextStyle(color: primaryBrandColor, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          title: Text(
                            r["reviewer"],
                            style: GoogleFonts.alexandria(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < r["rating"].floor() ? Iconsax.star1 : Iconsax.star,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r["comment"],
                                style: GoogleFonts.alexandria(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              ),
                            ],
                          ),
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

  Widget tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isDark ? primaryBrandColor.withOpacity(0.2) : primaryBrandColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: GoogleFonts.alexandria(
        color: isDark ? Colors.blue.shade300 : primaryBrandColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white12) : Border.all(color: Colors.grey.shade200),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              service.image,
              fit: BoxFit.cover,
              height: 160,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service.price,
                    style: GoogleFonts.alexandria(
                      color: isDark ? Colors.blue.shade400 : primaryBrandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.duration,
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: service.tags.map((t) => tag(t)).toList(),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Iconsax.star, size: 18, color: isDark ? Colors.blue.shade400 : primaryBrandColor),
                  onPressed: () => _showReviewsSheet(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: isDark ? Colors.blue.shade400 : primaryBrandColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text(
                    "Reviews",
                    style: GoogleFonts.alexandria(
                      color: isDark ? Colors.blue.shade400 : primaryBrandColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
                    boxShadow: [BoxShadow(color: primaryBrandColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Iconsax.calendar_tick, color: Colors.white, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.push(RoutesName.placeOrdersNavigate);
                    },
                    label: Text(
                      "Book Now",
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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