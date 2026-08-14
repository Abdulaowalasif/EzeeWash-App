import 'package:flutter/material.dart';
import 'app_icon_box.dart';
import '../../theme/app_text_styles.dart';

// ─── Contact row ──────────────────────────────────────────────────────────────

class AppContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;

  const AppContactRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AppIconBox(icon: icon, color: color, shape: BoxShape.circle),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption(isDark)),
              Text(value, style: AppTextStyles.rowTitle(isDark)),
            ],
          ),
        ],
      ),
    );
  }
}
