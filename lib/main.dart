// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/service/connectivity_service.dart';
import 'core/service/notification_service.dart';
import 'core/utils/theme_prefs.dart';
import 'ezzewash_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Cap the Flutter image cache to avoid unbounded memory growth ──────────
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  await dotenv.load(fileName: '.env');

  // ─── Load Saved Theme on App Start ─────────────────────────────────────────
  await ThemePrefs.load();

  Stripe.publishableKey = AppConstants.stripePubKey;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  await NotificationService.init(AppConstants.oneSignalAppId);

  await initDependencies();
  await ConnectivityService.instance.init();

  runApp(const EzzeWashApp());
}
