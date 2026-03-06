import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/routes_name.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final images = [
    'assets/services/Washing machine.png',
    'assets/services/Dry cleaning.png',
    'assets/services/Ironing board.png',
    'assets/services/Express delivery.png',
  ];

  final titles = ["Wash & Fold", "Dry Clean", "Iron & Press", "Express"];
  final subtitles = [
    "Professional washing and folding",
    "Premium dry cleaning",
    "Perfect ironing services",
    "Fastest delivery",
  ];
  final prices = ["12", "25", "10", "40"];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredServices = List.generate(images.length, (index) => index)
        .where(
          (i) => titles[i].toLowerCase().contains(searchQuery.toLowerCase()),
    )
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Sticky AppBar =====
            _buildAppBar(context, isDark),

            // ===== Scrollable Content =====
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive logic
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  double childAspectRatio = constraints.maxWidth > 600 ? 0.9 : 0.75;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSearchBox(isDark),
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Our Services",
                              style: GoogleFonts.alexandria(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(RoutesName.services),
                              child: Text(
                                "View All",
                                style: GoogleFonts.alexandria(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredServices.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final i = filteredServices[index];
                            return AnimatedServiceCard(
                              image: images[i],
                              title: titles[i],
                              subtitle: subtitles[i],
                              price: prices[i],
                              onPress: () => context.push(RoutesName.placeOrdersNavigate),
                              isDark: isDark,
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildQuickActions(context, isDark),
                        const SizedBox(height: 30),
                        _buildRecentOrders(context, isDark),
                        const SizedBox(height: 20), // Bottom padding
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EzeeWash",
                style: GoogleFonts.pacifico(
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Clean clothes, happy you!",
                style: GoogleFonts.alexandria(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.go(RoutesName.alerts),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.notification, color: Colors.white, size: 24),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2F2E98), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: "Search services...",
          hintStyle: GoogleFonts.alexandria(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(Iconsax.search_normal, color: isDark ? Colors.grey[400] : Colors.grey[400]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            onTap: () => context.push(RoutesName.placeOrdersNavigate),
            gradient: primaryGradient, // Filled with gradient
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.calendar_tick, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Book Now",
                  style: GoogleFonts.alexandria(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: AnimatedButton(
            onTap: () => context.push(RoutesName.trackOrdersNavigate),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            border: BorderSide(color: primaryColor.withOpacity(0.4), width: 1.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.truck, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Track Order",
                  style: GoogleFonts.alexandria(fontWeight: FontWeight.w600, color: primaryColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Orders",
              style: GoogleFonts.alexandria(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => context.go(RoutesName.orders),
              child: Text(
                "View All",
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        RecentOrderCard(
          id: '#EZ001',
          category: 'Wash & Fold',
          status: 'In Progress',
          date: 'Today, 10:00 AM',
          progress: 0.5,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        RecentOrderCard(
          id: '#EZ002',
          category: 'Dry Clean',
          status: 'Completed',
          date: 'Yesterday, 3:00 PM',
          progress: 1,
          isDark: isDark,
        ),
      ],
    );
  }
}

/// ================= Animated Service Card =================
class AnimatedServiceCard extends StatefulWidget {
  final String image, title, subtitle, price;
  final VoidCallback onPress;
  final bool isDark;

  const AnimatedServiceCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onPress,
    required this.isDark,
  });

  @override
  State<AnimatedServiceCard> createState() => _AnimatedServiceCardState();
}

class _AnimatedServiceCardState extends State<AnimatedServiceCard> {
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.95),
      onTapUp: (_) => setState(() => scale = 1),
      onTapCancel: () => setState(() => scale = 1),
      onTap: widget.onPress,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.isDark
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
            border: widget.isDark ? Border.all(color: Colors.white12) : Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(widget.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 2,
                child: Text(
                  widget.subtitle,
                  style: GoogleFonts.alexandria(
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "From ৳${widget.price}",
                style: GoogleFonts.alexandria(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= Animated Button =================
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;
  final BorderSide? border;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.gradient,
    this.border,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.95),
      onTapUp: (_) => setState(() => scale = 1),
      onTapCancel: () => setState(() => scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.gradient == null ? widget.color : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
            boxShadow: widget.gradient != null
                ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// ================= Recent Order Card =================
class RecentOrderCard extends StatelessWidget {
  final String id, category, status, date;
  final double progress;
  final bool isDark;

  const RecentOrderCard({
    super.key,
    required this.id,
    required this.category,
    required this.status,
    required this.date,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == "Completed";
    final statusColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B); // Emerald or Amber

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white12) : Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Iconsax.activity, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category,
                      style: GoogleFonts.alexandria(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.alexandria(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: GoogleFonts.alexandria(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              color: isCompleted ? statusColor : primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(progress * 100).toInt()}% Completed",
              style: GoogleFonts.alexandria(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}