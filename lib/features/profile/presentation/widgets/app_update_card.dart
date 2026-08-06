import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class SettingsAppUpdateCard extends StatefulWidget {
  final bool isDark;
  
  const SettingsAppUpdateCard({super.key, required this.isDark});

  @override
  State<SettingsAppUpdateCard> createState() => _SettingsAppUpdateCardState();
}

class _SettingsAppUpdateCardState extends State<SettingsAppUpdateCard> {
  String _currentVersion = 'Loading...';
  String _latestVersion = 'Loading...';
  String? _apkDownloadUrl;
  
  bool _isChecking = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _updateAvailable = false;

  final String _repoOwner = 'Abdulaowalasif';
  final String _repoName = 'EzeeWash-App';

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isChecking = true);
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      final response = await Dio().get(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String tagName = data['tag_name'] ?? '';
        _latestVersion = tagName.replaceAll('v', '');

        // Check if an apk asset exists
        final assets = data['assets'] as List;
        for (var asset in assets) {
          if (asset['name'].toString().endsWith('.apk')) {
            _apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }

        // Compare versions (simple logic, assuming x.y.z format)
        if (_latestVersion.compareTo(_currentVersion) > 0 && _apkDownloadUrl != null) {
          _updateAvailable = true;
        } else {
          _updateAvailable = false;
        }
      } else {
        _latestVersion = 'Unknown';
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      _latestVersion = 'Failed to fetch';
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_apkDownloadUrl == null) return;

    // Request permissions
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        if (mounted) AppSnackBar.show(context, 'Permission required to install update.', type: SnackBarType.error);
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

      await Dio().download(
        _apkDownloadUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() => _isDownloading = false);

      // Trigger installation
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done && mounted) {
        AppSnackBar.show(context, 'Failed to open installer: ${result.message}', type: SnackBarType.error);
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        setState(() => _isDownloading = false);
        AppSnackBar.show(context, 'Failed to download update.', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.refresh, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'App Update',
                  style: AppTextStyles.h4(widget.isDark).copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('Current Version', _currentVersion, widget.isDark),
          const SizedBox(height: 8),
          _buildRow('Latest Version', _isChecking ? 'Checking...' : _latestVersion, widget.isDark),
          const SizedBox(height: 16),
          
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption(widget.isDark),
            ),
          ] else if (_isChecking) ...[
             const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ] else if (_updateAvailable) ...[
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _downloadAndInstall,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   padding: const EdgeInsets.symmetric(vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: const Text('Update Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ] else ...[
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 12),
               decoration: BoxDecoration(
                 color: widget.isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(12),
               ),
               alignment: Alignment.center,
               child: Text(
                 "You're using the latest version.",
                 style: AppTextStyles.bodyMedium(widget.isDark).copyWith(
                   color: widget.isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                 ),
               ),
             )
          ]
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium(isDark)),
        Text(
          value,
          style: AppTextStyles.bodyMedium(isDark).copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
