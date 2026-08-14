import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsAppUpdateCard extends StatefulWidget {
  final bool isDark;
  final bool autoStartUpdate;

  const SettingsAppUpdateCard({
    super.key,
    required this.isDark,
    this.autoStartUpdate = false,
  });

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
  bool _hasError = false;

  final String _repoOwner = 'Abdulaowalasif';
  final String _repoName = 'ezze-wash-apk-release';

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  bool _isNewer(String latest, String current) {
    try {
      // Remove any non-numeric and non-dot characters (like spaces, \n, \r, etc.)
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final l = cleanLatest
          .split('.')
          .where((e) => e.isNotEmpty)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final c = cleanCurrent
          .split('.')
          .where((e) => e.isNotEmpty)
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final maxLength = l.length > c.length ? l.length : c.length;
      final maxIter = maxLength > 3 ? maxLength : 3;

      for (int i = 0; i < maxIter; i++) {
        final lv = i < l.length ? l[i] : 0;
        final cv = i < c.length ? c[i] : 0;
        if (lv > cv) return true;
        if (lv < cv) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Version compare error: $e');
      return false;
    }
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    setState(() {
      _isChecking = true;
      _hasError = false;
    });

    // Read current version first and update UI immediately
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _currentVersion = packageInfo.version);
    } catch (e) {
      if (mounted) setState(() => _currentVersion = 'Unknown');
    }

    // Fetch releases from GitHub (get latest 10 to ensure we find ones with APKs)
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases?per_page=10&page=1',
      );
      final githubToken = dotenv.env['GITHUB_PAT'] ?? '';

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'EzeeWash-App',
              if (githubToken.isNotEmpty)
                'Authorization': 'Bearer $githubToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('GitHub API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;

        Map<String, dynamic>? latestReleaseWithApk;
        String? foundApkUrl;

        for (final r in releases) {
          final release = r as Map<String, dynamic>;
          final assets = (release['assets'] as List?) ?? [];

          String? apkUrl;
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['url'] as String?;
              break;
            }
          }

          if (apkUrl != null) {
            latestReleaseWithApk = release;
            foundApkUrl = apkUrl;
            break;
          }
        }

        if (latestReleaseWithApk != null) {
          final tagName = (latestReleaseWithApk['tag_name'] as String? ?? '')
              .replaceAll('v', '');

          debugPrint('Latest tag: $tagName | APK URL: $foundApkUrl');

          if (mounted) {
            setState(() {
              _latestVersion = tagName.isEmpty ? 'No release yet' : tagName;
              _apkDownloadUrl = foundApkUrl;
              _updateAvailable =
                  tagName.isNotEmpty &&
                  foundApkUrl != null &&
                  _isNewer(tagName, _currentVersion);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _latestVersion = 'No releases yet';
            });
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint('GitHub: No releases found (404)');
        if (mounted) setState(() => _latestVersion = 'No releases yet');
      } else {
        debugPrint(
          'GitHub API error: ${response.statusCode} — ${response.body}',
        );
        if (mounted) {
          setState(() {
            _latestVersion = 'Error ${response.statusCode}';
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('GitHub fetch exception: $e');
      if (mounted) {
        setState(() {
          _latestVersion = 'Check failed';
          _hasError = true;
        });
      }
    }

    if (mounted) setState(() => _isChecking = false);
    if (widget.autoStartUpdate && _updateAvailable && !_isDownloading) {
      _downloadAndInstall();
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_apkDownloadUrl == null) return;

    // Request permissions
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        if (mounted) {
          AppSnackBar.show(
            context,
            'Permission required to install update.',
            type: SnackBarType.error,
          );
        }
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

      final githubToken = dotenv.env['GITHUB_PAT'] ?? '';

      await Dio().download(
        _apkDownloadUrl!,
        savePath,
        options: Options(
          headers: {
            if (githubToken.isNotEmpty) 'Authorization': 'Bearer $githubToken',
            'Accept': 'application/octet-stream',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() => _isDownloading = false);

      // Trigger Android package installer with explicit APK MIME type
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && mounted) {
        AppSnackBar.show(
          context,
          'Could not open installer: ${result.message}',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      if (mounted) {
        setState(() => _isDownloading = false);
        AppSnackBar.show(
          context,
          'Failed to download update.',
          type: SnackBarType.error,
        );
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

          if (!_isChecking && !_hasError && _updateAvailable) ...[
            Text(
              "You're using an old version.",
              style: AppTextStyles.body(
                widget.isDark,
              ).copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Please update to latest version.",
              style: AppTextStyles.bodyMedium(widget.isDark),
            ),
            const SizedBox(height: 12),
          ],

          _buildRow('Current Version', _currentVersion, widget.isDark),
          const SizedBox(height: 8),
          _buildRow(
            'Latest Version',
            _isChecking ? 'Checking...' : _latestVersion,
            widget.isDark,
          ),
          const SizedBox(height: 16),

          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption(widget.isDark),
            ),
          ] else if (_isChecking) ...[
            const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (_hasError) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkForUpdates,
                icon: const Icon(
                  Iconsax.refresh,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (_updateAvailable) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _downloadAndInstall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.grey.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                "Using latest version",
                style: AppTextStyles.bodyMedium(widget.isDark).copyWith(
                  color: widget.isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
