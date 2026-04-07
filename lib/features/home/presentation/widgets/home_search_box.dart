// lib/features/home/presentation/widgets/home_search_box.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';

class HomeSearchBox extends StatefulWidget {
  final bool isDark;
  final ValueChanged<String> onChanged;

  const HomeSearchBox({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<HomeSearchBox> createState() => _HomeSearchBoxState();
}

class _HomeSearchBoxState extends State<HomeSearchBox> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: _onChanged,
        style: AppTextStyles.input,
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: AppTextStyles.hint(widget.isDark),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: Colors.grey[400],
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: Colors.grey[400],
                    onPressed: () {
                      _debounce?.cancel();
                      _ctrl.clear();
                      widget.onChanged('');
                    },
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
