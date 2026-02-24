import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  /// Requests all relevant permissions (location + storage/media for image picker)
  static Future<bool> requestAllPermissions() async {
    List<Permission> permissions = [
      Permission.locationWhenInUse,
    ];

    // Add proper storage/media permission depending on platform
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_IMAGES
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        permissions.add(Permission.photos); // maps to READ_MEDIA_IMAGES
      } else {
        permissions.add(Permission.storage); // legacy storage permission
      }
    } else if (Platform.isIOS) {
      permissions.add(Permission.photos); // iOS photos permission
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Check if all requested permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    // Check if any permission is permanently denied
    bool permanentlyDenied =
    statuses.values.any((status) => status.isPermanentlyDenied);

    if (permanentlyDenied) {
      return false;
    }

    return allGranted;
  }
}