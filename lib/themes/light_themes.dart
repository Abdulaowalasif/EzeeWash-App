import 'package:flutter/material.dart';

ThemeData lightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white.withOpacity(0.8),
  appBarTheme: AppBarTheme(
    surfaceTintColor: Colors.white.withOpacity(0.8),
    elevation: 0,
    backgroundColor: Colors.white.withOpacity(0.8),
  ),

  inputDecorationTheme: InputDecorationThemeData(
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.grey),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.blueAccent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: Colors.blueAccent),
    ),
  ),
);
