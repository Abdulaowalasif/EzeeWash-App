import 'package:flutter/material.dart';

ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor:Colors.white.withOpacity(0.8),
  appBarTheme: AppBarTheme(
    surfaceTintColor: Colors.white.withOpacity(0.8),
    elevation: 0,
    backgroundColor: Colors.white.withOpacity(0.8),
  )
);
