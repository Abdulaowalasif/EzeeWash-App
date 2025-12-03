import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {

    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.storage,

    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    bool permanentlyDenied =
    statuses.values.any((status) => status.isPermanentlyDenied);

    if (permanentlyDenied) {
      return false;
    }

    return allGranted;
  }

}
