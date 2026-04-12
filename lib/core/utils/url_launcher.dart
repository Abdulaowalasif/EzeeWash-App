import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<bool> launch(
    String urlString, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final Uri uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      } else {
        // fallback to external app
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $urlString\n$e');
      return false;
    }
  }
}
