// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1D4BC7);
  static const secondary = Color(0xFF2F2E98);

  static const gradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightText = Color(0xFF0F172A);
  static const lightSubtext = Color(0xFF64748B);

  // Dark
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkText = Colors.white;
  static const darkSubtext = Color(0xFF94A3B8);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
}
