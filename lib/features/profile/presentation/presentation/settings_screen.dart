// lib/features/profile/presentation/presentation/settings_screen.dart

import 'dart:io';
import 'package:ezzewash/core/widgets/gradient_app_bar.dart';
import 'package:ezzewash/core/service/pdf_service.dart';
import 'package:ezzewash/features/orders/domain/entities/order_entity.dart';
import 'package:ezzewash/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:ezzewash/features/orders/presentation/bloc/orders_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/theme_prefs.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../routes/routes_name.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors
          .lightBackground,
      body: BlocConsumer<ProfileBloc, ProfileState > (
    listener: (ctx, state) {
      if (state is ProfileError) {
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(state.message, style: GoogleFonts.alexandria()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    },
    builder: (ctx, state) {
      if (state is ProfileLoading || state is ProfileInitial) {
        return _SettingsShimmer(isDark: isDark);
      }

      if (state is ProfileLoaded || state is ProfileUpdating) {
        final profile = state is ProfileLoaded
            ? (state as ProfileLoaded).profile
            : (state as ProfileUpdating).profile;
        return _SettingsContent(
          profile: profile,
          isDark: isDark,
          isUpdating: state is ProfileUpdating,
        );
      }

      if (state is ProfileError && (state as ProfileError).profile != null) {
        return _SettingsContent(
          profile: (state as ProfileError).profile!,
          isDark: isDark,
        );
      }

      return Column(
        children: [
          const GradientAppBar(title: "Settings"),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                      Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Could not load settings',
                      style: GoogleFonts.alexandria(color: AppColors.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ctx.read<ProfileBloc>().add(
                            const ProfileLoadRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
    ),
    );
  }
}

class _SettingsShimmer extends StatelessWidget {
  final bool isDark;

  const _SettingsShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GradientAppBar(title: "Settings"),
        Expanded(
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _shimmerBox(110),
                  const SizedBox(height: 20),
                  _shimmerBox(160),
                  const SizedBox(height: 20),
                  _shimmerBox(220),
                  const SizedBox(height: 20),
                  _shimmerBox(130),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox(double h) =>
      Container(
        height: h,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
      );
}

class _SettingsContent extends StatefulWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isUpdating;

  const _SettingsContent(
      {required this.profile, required this.isDark, this.isUpdating = false});

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  bool _editing = false;
  DateTime? _selectedReceiptDate;
  OrderEntity? _selectedOrderForReceipt;

  late final _nameCtrl = TextEditingController(
      text: widget.profile.fullName ?? '');
  late final _phoneCtrl = TextEditingController(
      text: widget.profile.phone ?? '');
  late final _addrCtrl = TextEditingController(
      text: widget.profile.address ?? '');

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
        fullName: _nameCtrl.text
            .trim()
            .isEmpty ? null : _nameCtrl.text.trim(),
        phone: _phoneCtrl.text
            .trim()
            .isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addrCtrl.text
            .trim()
            .isEmpty ? null : _addrCtrl.text.trim(),
      ),
    );
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated!', style: GoogleFonts.alexandria()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    context.read<ProfileBloc>().add(
        ProfileAvatarUpdateRequested(File(picked.path)));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final isDark = widget.isDark;

    return Column(
      children: [
        const GradientAppBar(title: "Settings"),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context), 20,
                Responsive.horizontalPadding(context), 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileCard(
                  profile: p,
                  isDark: isDark,
                  isUpdating: widget.isUpdating,
                  isEditing: _editing,
                  onEditToggle: () => setState(() => _editing = !_editing),
                  onPickAvatar: _pickAvatar,
                ),
                if (_editing) ...[
                  const SizedBox(height: 16),
                  _EditCard(nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      addrCtrl: _addrCtrl,
                      isDark: isDark,
                      onSave: _save,
                      onCancel: () => setState(() => _editing = false)),
                ],
                const SizedBox(height: 24),
                _SectionLabel(label: 'Account', isDark: isDark),
                const SizedBox(height: 10),
                _MenuCard(
                  isDark: isDark,
                  items: [
                    _MenuTile(icon: Iconsax.lock,
                        label: 'Change Password',
                        isDark: isDark,
                        onTap: () =>
                            context.push(RoutesName.changePasswordNavigate)),
                    _SwitchTile(icon: Iconsax.moon,
                        label: 'Dark Mode',
                        isDark: isDark,
                        value: isDark,
                        onChanged: (v) =>
                            ThemePrefs.save(
                            v ? ThemeMode.dark : ThemeMode.light)),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: 'Order Receipts', isDark: isDark),
                const SizedBox(height: 10),
                BlocBuilder<OrdersBloc, OrdersState>(
                  builder: (context, state) {
                    if (state is OrdersLoaded && state.orders.isNotEmpty) {
                      final filteredOrders = _selectedReceiptDate == null
                          ? state.orders
                          : state.orders.where((order) =>
                      order.createdAt.year == _selectedReceiptDate!.year &&
                          order.createdAt.month ==
                              _selectedReceiptDate!.month && order.createdAt
                          .day == _selectedReceiptDate!.day).toList();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors
                              .lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors
                              .darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedReceiptDate ??
                                      DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) =>
                                      Theme(
                                        data: isDark
                                            ? ThemeData.dark().copyWith(
                                            colorScheme: const ColorScheme.dark(
                                                primary: AppColors.primary))
                                            : ThemeData.light().copyWith(
                                            colorScheme: const ColorScheme
                                                .light(
                                                primary: AppColors.primary)),
                                        child: child!,
                                      ),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedReceiptDate = picked;
                                    _selectedOrderForReceipt = null;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Iconsax.calendar, size: 18,
                                        color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedReceiptDate == null
                                          ? 'Filter by Date (Optional)'
                                          : DateFormat('MMM dd, yyyy').format(
                                          _selectedReceiptDate!),
                                      style: GoogleFonts.alexandria(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightText),
                                    ),
                                    const Spacer(),
                                    if (_selectedReceiptDate !=
                                        null) IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        onPressed: () =>
                                            setState(() {
                                              _selectedReceiptDate = null;
                                              _selectedOrderForReceipt = null;
                                            })),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<OrderEntity>(
                              value: _selectedOrderForReceipt,
                              isExpanded: true,
                              hint: Text(
                                filteredOrders.isEmpty
                                    ? 'No orders on this date'
                                    : 'Select Order Number',
                                style: GoogleFonts.alexandria(fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkSubtext
                                        : AppColors.lightSubtext),
                              ),
                              dropdownColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)),
                              ),
                              items: filteredOrders.map((order) {
                                return DropdownMenuItem<OrderEntity>(
                                  value: order,
                                  child: Text('Order #${order.orderNumber}',
                                      style: GoogleFonts.alexandria(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightText)),
                                );
                              }).toList(),
                              onChanged: filteredOrders.isEmpty ? null : (
                                  OrderEntity? newValue) =>
                                  setState(() =>
                              _selectedOrderForReceipt = newValue),
                            ),
                            if (_selectedOrderForReceipt != null) ...[
                              const SizedBox(height: 16),
                              _MenuTile(
                                icon: Iconsax.receipt_2,
                                label: 'Download Receipt',
                                isDark: isDark,
                                trailing: Icon(
                                    Icons.download_for_offline_rounded,
                                    size: 20,
                                    color: AppColors.primary.withOpacity(0.8)),
                                onTap: () async {
                                  final pdfData = await PdfService
                                      .generateOrderInvoice(
                                      _selectedOrderForReceipt!);
                                  await Printing.layoutPdf(
                                      onLayout: (format) async => pdfData,
                                      name: 'Invoice_${_selectedOrderForReceipt!
                                          .orderNumber}');
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors
                              .lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? AppColors
                              .darkBorder : AppColors.lightBorder)),
                      child: Center(
                          child: Text('No orders found', style: GoogleFonts
                              .alexandria(fontSize: 12,
                              color: isDark ? AppColors.darkSubtext : AppColors
                                  .lightSubtext))),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _SectionLabel(label: 'Support', isDark: isDark),
                const SizedBox(height: 10),
                _MenuCard(
                  isDark: isDark,
                  items: [
                    _MenuTile(icon: Iconsax.message_question,
                        label: 'Help & Support',
                        isDark: isDark,
                        onTap: () =>
                            context.push(RoutesName.helpSupportNavigate)),
                    _MenuTile(icon: Iconsax.document_text_1,
                        label: 'Terms & Policy',
                        isDark: isDark,
                        onTap: () =>
                            context.push(RoutesName.termsPolicyNavigate)),
                    _MenuTile(icon: Iconsax.global,
                        label: 'Visit Website',
                        isDark: isDark,
                        onTap: () {}),
                  ],
                ),
                const SizedBox(height: 32),
                _LogoutButton(isDark: isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark, isUpdating, isEditing;
  final VoidCallback onEditToggle, onPickAvatar;

  const _ProfileCard(
      {required this.profile, required this.isDark, required this.isUpdating, required this.isEditing, required this.onEditToggle, required this.onPickAvatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2)),
                  child: ClipOval(
                    child: profile.avatarUrl != null
                        ? Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback())
                        : _avatarFallback(),
                  ),
                ),
                Positioned(bottom: 0,
                    right: 0,
                    child: Container(padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors
                                .lightBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.3))),
                        child: const Icon(
                            Icons.camera_alt_rounded, color: AppColors.primary,
                            size: 14))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName ?? 'User', style: GoogleFonts.alexandria(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(profile.email ?? '', style: GoogleFonts.alexandria(
                    color: isDark ? AppColors.darkSubtext : AppColors
                        .lightSubtext, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (profile.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(profile.phone!, style: GoogleFonts.alexandria(
                      color: isDark ? AppColors.darkSubtext : AppColors
                          .lightSubtext, fontSize: 13))
                ],
              ],
            ),
          ),
          if (isUpdating) const SizedBox(width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2)) else
            GestureDetector(onTap: onEditToggle,
                child: Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(isEditing ? Icons.close_rounded : Iconsax.edit,
                        color: AppColors.primary, size: 20))),
        ],
      ),
    );
  }

  Widget _avatarFallback() =>
      Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(child: Text((profile.fullName?.isNotEmpty == true
          ? profile.fullName![0]
          : profile.email?[0] ?? 'U').toUpperCase(),
          style: GoogleFonts.pacifico(
              color: AppColors.primary, fontSize: 28))));
}

class _EditCard extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, addrCtrl;
  final bool isDark;
  final VoidCallback onSave, onCancel;

  const _EditCard(
      {required this.nameCtrl, required this.phoneCtrl, required this.addrCtrl, required this.isDark, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile', style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.lightText)),
            const SizedBox(height: 18),
            TextField(controller: nameCtrl,
                style: GoogleFonts.alexandria(fontSize: 14),
                decoration: _deco('Full name', Iconsax.user, isDark)),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl,
                style: GoogleFonts.alexandria(fontSize: 14),
                keyboardType: TextInputType.phone,
                decoration: _deco('Phone number', Iconsax.call, isDark)),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl,
                style: GoogleFonts.alexandria(fontSize: 14),
                maxLines: 2,
                decoration: _deco(
                    'Address', Icons.location_on_outlined, isDark)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onCancel,
                    style: OutlinedButton.styleFrom(side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text('Cancel', style: GoogleFonts.alexandria(
                        color: isDark ? Colors.white70 : Colors.black54)))),
                const SizedBox(width: 12),
                Expanded(child: Container(decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                    child: ElevatedButton(onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text('Save', style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))))),
              ],
            ),
          ],
        ),
      );

  InputDecoration _deco(String hint, IconData icon, bool isDark) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(
            icon, color: AppColors.primary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : AppColors
            .lightBackground,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label.toUpperCase(), style: GoogleFonts.alexandria(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)));
}

class _MenuCard extends StatelessWidget {
  final List<Widget> items;
  final bool isDark;

  const _MenuCard({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Container(
        decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        child: Column(children: List.generate(items.length, (i) =>
            Column(
            children: [
              items[i],
              if (i < items.length - 1) Divider(height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  indent: 56)
            ]))),
      );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Widget? trailing;

  const _MenuTile(
      {required this.icon, required this.label, required this.onTap, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) =>
      ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary)),
        title: Text(label, style: GoogleFonts.alexandria(fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.lightText)),
        trailing: trailing ?? const Icon(
            Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchTile(
      {required this.icon, required this.label, required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) =>
      ListTile(
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary)),
        title: Text(label, style: GoogleFonts.alexandria(fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.lightText)),
        trailing: Switch(value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class _LogoutButton extends StatelessWidget {
  final bool isDark;

  const _LogoutButton({required this.isDark});

  @override
  Widget build(BuildContext context) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
          label: Text('Sign Out', style: GoogleFonts.alexandria(
              color: AppColors.error, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
        ),
      );

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Sign Out?',
                style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
            content: Text('Are you sure you want to sign out?',
                style: GoogleFonts.alexandria(fontSize: 14)),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancel', style: GoogleFonts.alexandria(
                      color: AppColors.primary, fontWeight: FontWeight.w600))),
              TextButton(onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
                  child: Text('Sign Out', style: GoogleFonts.alexandria(
                      color: AppColors.error, fontWeight: FontWeight.w600))),
            ],
          ),
    );
  }
}