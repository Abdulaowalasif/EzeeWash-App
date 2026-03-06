import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AppNotification {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color themeColor;
  bool isUnread;

  AppNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.themeColor,
    this.isUnread = false,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<AppNotification> notifications = [
    AppNotification(
      title: "Order Ready for Pickup",
      description: "Your dry cleaning order #EZ011 is ready for pickup at Downtown Store.",
      time: "2 min ago",
      icon: Icons.check_circle_rounded,
      themeColor: const Color(0xff10B981),
      isUnread: true,
    ),
    AppNotification(
      title: "Order Picked Up",
      description: "Laundry picked up from Uptown Store successfully.",
      time: "10 min ago",
      icon: Icons.local_shipping_rounded,
      themeColor: const Color(0xff2563EB),
      isUnread: true,
    ),
    AppNotification(
      title: "20% Off Your Next Order",
      description: "Use code SAVE20 on your next Wash & Fold service.",
      time: "30 min ago",
      icon: Icons.card_giftcard_rounded,
      themeColor: const Color(0xffD97706),
    ),
    AppNotification(
      title: "Scheduled Pickup Reminder",
      description: "Your pickup is scheduled tomorrow at 3:00 PM.",
      time: "1 hour ago",
      icon: Icons.calendar_today_rounded,
      themeColor: const Color(0xff7C3AED),
    ),
    AppNotification(
      title: "Order Completed",
      description: "Your ironing order #EZ012 is completed at Midtown Store.",
      time: "2 hours ago",
      icon: Icons.done_all_rounded,
      themeColor: const Color(0xff10B981),
      isUnread: true,
    ),
    AppNotification(
      title: "New Offer: Free Pickup",
      description: "Avail free pickup on orders above ৳500 until Feb 28.",
      time: "3 hours ago",
      icon: Icons.local_mall_rounded,
      themeColor: const Color(0xff2563EB),
    ),
  ];

  void markAsRead(int index) {
    setState(() {
      notifications[index].isUnread = false;
    });
  }

  void markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isUnread = false;
      }
    });
  }

  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notifications",
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (notifications.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => notifications.clear()),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (notifications.any((n) => n.isUnread))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: markAllAsRead,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      "Mark all as read",
                      style: GoogleFonts.alexandria(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: notifications.isNotEmpty
                ? ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: NotificationCard(
                    notification: notifications[index],
                    onMarkRead: () => markAsRead(index),
                    onRemove: () => removeNotification(index),
                    isDark: isDark,
                  ),
                );
              },
            )
                : _buildEmptyState(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No Notifications Yet",
            style: GoogleFonts.alexandria(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you when something pops up!",
            style: GoogleFonts.alexandria(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;
  final VoidCallback onRemove;
  final bool isDark;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: notification.isUnread
            ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
            : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: notification.themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(notification.icon, color: notification.themeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.alexandria(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.grey),
                    ),
                  ),
                  if (notification.isUnread)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          gradient: primaryGradient,
                          shape: BoxShape.circle,
                        ),
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
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    notification.time,
                    style: GoogleFonts.alexandria(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (notification.isUnread)
                TextButton(
                  onPressed: onMarkRead,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Mark as read",
                    style: GoogleFonts.alexandria(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
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