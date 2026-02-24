import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotification {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  bool isUnread;

  AppNotification({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    this.isUnread = false,
  });
}

/// NOTIFICATION SCREEN
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<AppNotification> notifications = [
    AppNotification(
      title: "Order Ready for Pickup",
      description:
          "Your dry cleaning order #EZ002 is ready for pickup at Shopping Mall location.",
      time: "2 minutes ago",
      icon: Icons.check,
      iconBgColor: const Color(0xffD1FAE5),
      iconColor: const Color(0xff10B981),
      isUnread: true,
    ),
    AppNotification(
      title: "Order Picked Up",
      description:
          "We have successfully picked up your laundry from 123 Main Street.",
      time: "1 hour ago",
      icon: Icons.local_shipping,
      iconBgColor: const Color(0xffDBEAFE),
      iconColor: const Color(0xff2563EB),
      isUnread: true,
    ),
    AppNotification(
      title: "20% Off Your Next Order",
      description:
          "Use code SAVE20 on your next wash & fold service. Valid until Jan 31st.",
      time: "3 hours ago",
      icon: Icons.card_giftcard,
      iconBgColor: const Color(0xffFEF3C7),
      iconColor: const Color(0xffD97706),
    ),
    AppNotification(
      title: "Scheduled Pickup Reminder",
      description:
          "Don't forget! Your pickup is scheduled for tomorrow at 2:00 PM.",
      time: "1 day ago",
      icon: Icons.calendar_today,
      iconBgColor: const Color(0xffEDE9FE),
      iconColor: const Color(0xff7C3AED),
    ),
    AppNotification(
      title: "Order Ready for Pickup",
      description:
          "Your dry cleaning order #EZ002 is ready for pickup at Shopping Mall location.",
      time: "2 minutes ago",
      icon: Icons.check,
      iconBgColor: const Color(0xffD1FAE5),
      iconColor: const Color(0xff10B981),
      isUnread: true,
    ),
    AppNotification(
      title: "Order Picked Up",
      description:
          "We have successfully picked up your laundry from 123 Main Street.",
      time: "1 hour ago",
      icon: Icons.local_shipping,
      iconBgColor: const Color(0xffDBEAFE),
      iconColor: const Color(0xff2563EB),
      isUnread: true,
    ),
    AppNotification(
      title: "20% Off Your Next Order",
      description:
          "Use code SAVE20 on your next wash & fold service. Valid until Jan 31st.",
      time: "3 hours ago",
      icon: Icons.card_giftcard,
      iconBgColor: const Color(0xffFEF3C7),
      iconColor: const Color(0xffD97706),
    ),
    AppNotification(
      title: "Scheduled Pickup Reminder",
      description:
          "Don't forget! Your pickup is scheduled for tomorrow at 2:00 PM.",
      time: "1 day ago",
      icon: Icons.calendar_today,
      iconBgColor: const Color(0xffEDE9FE),
      iconColor: const Color(0xff7C3AED),
    ),
  ];

  /// MARK AS READ
  void markAsRead(int index) {
    setState(() {
      notifications[index].isUnread = false;
    });
  }

  void markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isUnread = false;
      }
    });
  }

  /// REMOVE NOTIFICATION
  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        actions: [
          GestureDetector(
            onTap: markAllAsRead,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                "Mark all as read",
                style: GoogleFonts.alexandria(color: Colors.blue),
              ),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: notifications.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: NotificationCard(
                    notification: notification,
                    onMarkRead: () => markAsRead(index),
                    onRemove: () => removeNotification(index),
                  ),
                );
              },
            )
          : const Center(child: Text("No Notifications")),
    );
  }
}

/// NOTIFICATION CARD
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onMarkRead;
  final VoidCallback onRemove;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onMarkRead,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: notification.isUnread
            ? Border.all(color: const Color(0xff93C5FD), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: notification.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.icon, color: notification.iconColor),
              ),
              const SizedBox(width: 14),

              /// TITLE
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              /// UNREAD DOT
              if (notification.isUnread)
                Container(
                  height: 8,
                  width: 8,
                  margin: const EdgeInsets.only(right: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),

              /// CLOSE BUTTON
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// DESCRIPTION
          Text(
            notification.description,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 12),

          /// TIME + MARK READ
          Row(
            children: [
              Text(
                notification.time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              if (notification.isUnread)
                GestureDetector(
                  onTap: onMarkRead,
                  child: const Text(
                    "Mark as read",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xff2563EB),
                      fontWeight: FontWeight.w500,
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
