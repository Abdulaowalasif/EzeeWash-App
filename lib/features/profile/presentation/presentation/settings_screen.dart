// lib/features/profile/presentation/presentation/settings_screen.dart
//
// Refactored: screen owns only state + BLoC wiring.
// All UI widgets live in ../widgets/settings_widgets.dart.
// Snack bars use AppSnackBar — no inline SnackBar construction.

import 'dart:io';
import 'package:ezzewash/core/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/theme_prefs.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../routes/routes_name.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/app_update_card.dart';

class SettingsScreen extends StatelessWidget {
  final bool autoStartUpdate;
  const SettingsScreen({super.key, this.autoStartUpdate = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (ctx, state) {
          if (state is ProfileError) {
            AppSnackBar.show(ctx, state.message, type: SnackBarType.error);
          }
        },
        builder: (ctx, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return _SettingsShimmer(isDark: isDark);
          }
          if (state is ProfileLoaded || state is ProfileUpdating) {
            final profile = state is ProfileLoaded
                ? (state).profile
                : (state as ProfileUpdating).profile;
            return _SettingsBody(
              profile: profile,
              isDark: isDark,
              isUpdating: state is ProfileUpdating,
              autoStartUpdate: autoStartUpdate,
            );
          }
          if (state is ProfileError && (state).profile != null) {
            return _SettingsBody(
              profile: (state).profile!,
              isDark: isDark,
              autoStartUpdate: autoStartUpdate,
            );
          }
          return Column(
            children: [
              const GradientAppBar(title: 'Settings'),
              Expanded(
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  message: 'Could not load settings',
                  subtitle: 'Tap retry to try again',
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Loading shimmer ──────────────────────────────────────────────────────────

class _SettingsShimmer extends StatelessWidget {
  final bool isDark;

  const _SettingsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const GradientAppBar(title: 'Settings'),
      Expanded(
        child: Shimmer.fromColors(
          baseColor: AppShimmerColors.base(isDark),
          highlightColor: AppShimmerColors.highlight(isDark),
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                AppShimmerBox(height: 110, radius: 24),
                SizedBox(height: 20),
                AppShimmerBox(height: 160, radius: 24),
                SizedBox(height: 20),
                AppShimmerBox(height: 220, radius: 24),
                SizedBox(height: 20),
                AppShimmerBox(height: 130, radius: 24),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _SettingsBody extends StatefulWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isUpdating;
  final bool autoStartUpdate;

  const _SettingsBody({
    required this.profile,
    required this.isDark,
    this.isUpdating = false,
    this.autoStartUpdate = false,
  });

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  bool _editing = false;
  late final _nameCtrl = TextEditingController(
    text: widget.profile.fullName ?? '',
  );
  late final _phoneCtrl = TextEditingController(
    text: widget.profile.phone ?? '',
  );
  late final _addrCtrl = TextEditingController(
    text: widget.profile.address?.address ?? '',
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addrCtrl.text.trim().isEmpty
            ? null
            : AddressEntity(label: 'Home', address: _addrCtrl.text.trim()),
      ),
    );
    setState(() => _editing = false);
    AppSnackBar.show(context, 'Profile updated!');
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;
    context.read<ProfileBloc>().add(
      ProfileAvatarUpdateRequested(File(picked.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      children: [
        const GradientAppBar(title: 'Settings'),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              20,
              Responsive.horizontalPadding(context),
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsProfileCard(
                  profile: widget.profile,
                  isDark: isDark,
                  isUpdating: widget.isUpdating,
                  isEditing: _editing,
                  onEditToggle: () => setState(() => _editing = !_editing),
                  onPickAvatar: _pickAvatar,
                ),
                if (_editing) ...[
                  const SizedBox(height: 16),
                  SettingsEditCard(
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    addrCtrl: _addrCtrl,
                    isDark: isDark,
                    onSave: _save,
                    onCancel: () => setState(() => _editing = false),
                  ),
                ],
                const SizedBox(height: 24),
                SettingsSectionLabel(label: 'App Update', isDark: isDark),
                const SizedBox(height: 10),
                SettingsAppUpdateCard(
                  isDark: isDark,
                  autoStartUpdate: widget.autoStartUpdate,
                ),
                const SizedBox(height: 24),
                SettingsSectionLabel(label: 'Account', isDark: isDark),
                const SizedBox(height: 10),
                SettingsMenuCard(
                  isDark: isDark,
                  items: [
                    SettingsMenuTile(
                      icon: Iconsax.lock,
                      label: 'Change Password',
                      isDark: isDark,
                      onTap: () =>
                          context.push(RoutesName.changePasswordNavigate),
                    ),
                    SettingsSwitchTile(
                      icon: Iconsax.moon,
                      label: 'Dark Mode',
                      isDark: isDark,
                      value: isDark,
                      onChanged: (v) =>
                          ThemePrefs.save(v ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SettingsSectionLabel(label: 'Order Receipts', isDark: isDark),
                const SizedBox(height: 10),
                SettingsReceiptPicker(isDark: isDark),
                const SizedBox(height: 24),
                SettingsSectionLabel(label: 'Support', isDark: isDark),
                const SizedBox(height: 10),
                SettingsMenuCard(
                  isDark: isDark,
                  items: [
                    SettingsMenuTile(
                      icon: Iconsax.message_question,
                      label: 'Help & Support',
                      isDark: isDark,
                      onTap: () => context.push(RoutesName.helpSupportNavigate),
                    ),
                    SettingsMenuTile(
                      icon: Iconsax.document_text_1,
                      label: 'Terms & Policy',
                      isDark: isDark,
                      onTap: () => context.push(RoutesName.termsPolicyNavigate),
                    ),
                    SettingsMenuTile(
                      icon: Iconsax.global,
                      label: 'Visit Website',
                      isDark: isDark,
                      onTap: () {
                        UrlLauncherHelper.launch(
                          "https://ezzewash.vercel.app/",
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SettingsLogoutButton(isDark: isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
