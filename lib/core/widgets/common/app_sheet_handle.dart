import 'package:flutter/material.dart';

// ─── Bottom-sheet drag handle ─────────────────────────────────────────────────

class AppSheetHandle extends StatelessWidget {
  final bool isDark;
  const AppSheetHandle({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
