// lib/features/profile/presentation/presentation/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      // Removed root SafeArea so the custom header can draw behind the status bar
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (ctx, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(ctx).clearSnackBars();
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message, style: GoogleFonts.alexandria()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ));
          }
        },
        builder: (ctx, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return Column(
              children: [
                const _FallbackAppBar(),
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }

          // ProfileUpdating carries the last known profile — keep showing content
          if (state is ProfileLoaded || state is ProfileUpdating) {
            final profile = state is ProfileLoaded
                ? (state as ProfileLoaded).profile
                : (state as ProfileUpdating).profile;
            return _ProfileContent(
              profile: profile,
              isDark: isDark,
              isUpdating: state is ProfileUpdating,
            );
          }

          // ProfileError after avatar/text update — stale profile is attached
          if (state is ProfileError && (state as ProfileError).profile != null) {
            return _ProfileContent(
              profile: (state as ProfileError).profile!,
              isDark: isDark,
            );
          }

          // ProfileError on initial load (no profile cached) → show retry
          return Column(
            children: [
              const _FallbackAppBar(),
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Could not load profile', style: GoogleFonts.alexandria(color: AppColors.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ctx.read<ProfileBloc>().add(const ProfileLoadRequested()),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Basic Header for Loading/Error States ─────────────────────────────────────
class _FallbackAppBar extends StatelessWidget {
  const _FallbackAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Text(
            'Profile',
            style: GoogleFonts.alexandria(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main Profile Content ─────────────────────────────────────────────────────
class _ProfileContent extends StatefulWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isUpdating;
  const _ProfileContent({required this.profile, required this.isDark, this.isUpdating = false});
  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool _editing = false;
  late final _nameCtrl = TextEditingController(text: widget.profile.fullName ?? '');
  late final _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
  late final _addrCtrl = TextEditingController(text: widget.profile.address ?? '');

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address: _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
    ));
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Profile updated!', style: GoogleFonts.alexandria()),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    context.read<ProfileBloc>().add(ProfileAvatarUpdateRequested(File(picked.path)));
  }

  Widget _avatarFallback(ProfileEntity p) => Container(
    color: Colors.white.withOpacity(0.2),
    child: Center(child: Text(
      ((p.fullName?.isNotEmpty == true ? p.fullName![0] : p.email?[0] ?? 'U')).toUpperCase(),
      style: GoogleFonts.pacifico(color: Colors.white, fontSize: 28),
    )),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final isDark = widget.isDark;

    return Column(
      children: [
        // ── Custom Full-Width Profile Header ─────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: ClipOval(
                            child: p.avatarUrl != null
                                ? Image.network(p.avatarUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback(p))
                                : _avatarFallback(p),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName ?? 'User',
                          style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.email ?? '',
                          style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (p.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            p.phone!,
                            style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.isUpdating)
                    const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _editing = !_editing),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _editing ? Icons.close_rounded : Iconsax.edit,
                          color: Colors.white, size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Scrollable Body ───────────────────────────────────────────────────
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
              children: [
                // ── Edit form ─────────────────────────────────────────────────
                if (_editing)
                  _EditCard(
                    nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl, addrCtrl: _addrCtrl,
                    isDark: isDark, onSave: _save, onCancel: () => setState(() => _editing = false),
                  ),

                // ── Menu ─────────────────────────────────────────────────────
                _MenuSection(title: 'Account', isDark: isDark, items: [
                  _MenuItem(icon: Iconsax.location, label: 'Saved Addresses', isDark: isDark,
                      onTap: () => context.push(RoutesName.addressNavigate)),
                  _MenuItem(icon: Iconsax.notification, label: 'Notifications', isDark: isDark,
                      onTap: () => context.go(RoutesName.alerts)),
                ]),
                const SizedBox(height: 16),
                _MenuSection(title: 'Support', isDark: isDark, items: [
                  _MenuItem(icon: Iconsax.message_question, label: 'Help & Support', isDark: isDark,
                      onTap: () => context.push(RoutesName.helpSupportNavigate)),
                  _MenuItem(icon: Iconsax.smart_home, label: 'Bubble Bot (AI)', isDark: isDark,
                      onTap: () => context.push(RoutesName.chatBotNavigate)),
                  _MenuItem(icon: Iconsax.document_text_1, label: 'Terms & Policy', isDark: isDark,
                      onTap: () => context.push(RoutesName.termsPolicyNavigate)),
                ]),
                const SizedBox(height: 24),
                _LogoutBtn(isDark: isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditCard extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, addrCtrl;
  final bool isDark;
  final VoidCallback onSave, onCancel;
  const _EditCard({required this.nameCtrl, required this.phoneCtrl, required this.addrCtrl,
    required this.isDark, required this.onSave, required this.onCancel});

  InputDecoration _deco(String hint, IconData icon, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 20),
    filled: true,
    fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    ),
    child: Column(children: [
      Text('Edit Profile', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 16,
          color: isDark ? Colors.white : AppColors.lightText)),
      const SizedBox(height: 18),
      TextField(controller: nameCtrl, style: GoogleFonts.alexandria(fontSize: 14),
          decoration: _deco('Full name', Iconsax.user, isDark)),
      const SizedBox(height: 12),
      TextField(controller: phoneCtrl, style: GoogleFonts.alexandria(fontSize: 14),
          keyboardType: TextInputType.phone,
          decoration: _deco('Phone number', Iconsax.call, isDark)),
      const SizedBox(height: 12),
      TextField(controller: addrCtrl, style: GoogleFonts.alexandria(fontSize: 14),
          maxLines: 2, decoration: _deco('Address', Icons.location_on_outlined, isDark)),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Cancel', style: GoogleFonts.alexandria(color: isDark ? Colors.white70 : Colors.black54)),
        )),
        const SizedBox(width: 12),
        Expanded(child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )),
      ]),
    ]),
  );
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool isDark;
  const _MenuSection({required this.title, required this.items, required this.isDark});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title, style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext))),
    Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(children: List.generate(items.length, (i) => Column(children: [
        items[i],
        if (i < items.length - 1)
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder, indent: 56),
      ]))),
    ),
  ]);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _MenuItem({required this.icon, required this.label, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: AppColors.primary)),
    title: Text(label, style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.lightText)),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class _LogoutBtn extends StatelessWidget {
  final bool isDark;
  const _LogoutBtn({required this.isDark});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sign Out?', style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to sign out?', style: GoogleFonts.alexandria(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              child: Text('Sign Out', style: GoogleFonts.alexandria(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
      label: Text('Sign Out', style: GoogleFonts.alexandria(color: AppColors.error, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}