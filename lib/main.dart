import 'package:ezeewash/core/permissions/permissions.dart';
import 'package:ezeewash/routes/app_routes.dart';
import 'package:ezeewash/themes/dark_themes.dart';
import 'package:ezeewash/themes/light_themes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    PermissionService.requestAllPermissions();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: lightTheme(),
      routerConfig: appRouter,
    );
  }
}
