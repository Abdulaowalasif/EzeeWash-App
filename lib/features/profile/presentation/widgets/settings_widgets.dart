// lib/features/profile/presentation/widgets/settings_widgets.dart
//
// All UI widgets for the settings screen, extracted so the screen only
// owns state (editing toggle, receipt date) and BLoC wiring.
//
// Exports:
//   SettingsProfileCard    – avatar + name/email/phone + edit toggle
//   SettingsEditCard       – editable name/phone/address fields + save/cancel
//   SettingsMenuCard       – bordered card wrapping a list of tiles with dividers
//   SettingsMenuTile       – icon + label + trailing arrow list tile
//   SettingsSwitchTile     – icon + label + Switch list tile
//   SettingsSectionLabel   – small uppercased section heading
//   SettingsLogoutButton   – red outlined sign-out button with confirm dialog
//   SettingsReceiptPicker  – date + order dropdown + download tile

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/service/pdf_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_state.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

// ─── Section label ────────────────────────────────────────────────────────────

class SettingsSectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const SettingsSectionLabel(
      {super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.alexandria(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
            color: isDark
                ? AppColors.darkSubtext
                : AppColors.lightSubtext,
          ),
        ),
      );
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class SettingsProfileCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;
  final bool isUpdating;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final VoidCallback onPickAvatar;

  const SettingsProfileCard({
    super.key,
    required this.profile,
    required this.isDark,
    required this.isUpdating,
    required this.isEditing,
    required this.onEditToggle,
    required this.onPickAvatar,
  });

  Widget _avatarFallback() => Container(
        color: AppColors.primary.withOpacity(0.1),
        child: Center(
          child: Text(
            (profile.fullName?.isNotEmpty == true
                    ? profile.fullName![0]
                    : profile.email?[0] ?? 'U')
                .toUpperCase(),
            style: GoogleFonts.pacifico(
                color: AppColors.primary, fontSize: 28),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary, width: 2),
                  ),
                  child: ClipOval(
                    child: profile.avatarUrl != null
                        ? Image.network(
                            profile.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarFallback(),
                          )
                        : _avatarFallback(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primary, size: 14),
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
                  profile.fullName ?? 'User',
                  style: GoogleFonts.alexandria(
                    color: isDark ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? '',
                  style: GoogleFonts.alexandria(
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phone!,
                    style: GoogleFonts.alexandria(
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUpdating)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: onEditToggle,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.close_rounded : Iconsax.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Edit card ────────────────────────────────────────────────────────────────

class SettingsEditCard extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, addrCtrl;
  final bool isDark;
  final VoidCallback onSave, onCancel;

  const SettingsEditCard({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addrCtrl,
    required this.isDark,
    required this.onSave,
    required this.onCancel,
  });

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon,
            color: AppColors.primary.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.alexandria(fontSize: 14),
              decoration: _deco('Full name', Iconsax.user),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              style: GoogleFonts.alexandria(fontSize: 14),
              keyboardType: TextInputType.phone,
              decoration: _deco('Phone number', Iconsax.call),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addrCtrl,
              style: GoogleFonts.alexandria(fontSize: 14),
              maxLines: 2,
              decoration:
                  _deco('Address', Icons.location_on_outlined),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.alexandria(
                          color: isDark
                              ? Colors.white70
                              : Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.alexandria(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ─── Menu card ────────────────────────────────────────────────────────────────

class SettingsMenuCard extends StatelessWidget {
  final List<Widget> items;
  final bool isDark;

  const SettingsMenuCard(
      {super.key, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: List.generate(
            items.length,
            (i) => Column(children: [
              items[i],
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  indent: 56,
                ),
            ]),
          ),
        ),
      );
}

// ─── Menu tile ────────────────────────────────────────────────────────────────

class SettingsMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Widget? trailing;

  const SettingsMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

// ─── Switch tile ──────────────────────────────────────────────────────────────

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.lightText,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

// ─── Logout button ────────────────────────────────────────────────────────────

class SettingsLogoutButton extends StatelessWidget {
  final bool isDark;

  const SettingsLogoutButton({super.key, required this.isDark});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out?',
            style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.alexandria(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.alexandria(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context
                  .read<AuthBloc>()
                  .add(const AuthSignOutRequested());
            },
            child: Text('Sign Out',
                style: GoogleFonts.alexandria(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout_rounded,
              color: AppColors.error),
          label: Text(
            'Sign Out',
            style: GoogleFonts.alexandria(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: AppColors.error.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
}

// ─── Receipt picker ───────────────────────────────────────────────────────────

class SettingsReceiptPicker extends StatefulWidget {
  final bool isDark;

  const SettingsReceiptPicker({super.key, required this.isDark});

  @override
  State<SettingsReceiptPicker> createState() =>
      _SettingsReceiptPickerState();
}

class _SettingsReceiptPickerState extends State<SettingsReceiptPicker> {
  DateTime? _selectedDate;
  OrderEntity? _selectedOrder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is! OrdersLoaded || state.orders.isEmpty) {
          return _emptyCard();
        }

        final filtered = _selectedDate == null
            ? state.orders
            : state.orders.where((o) =>
                o.createdAt.year == _selectedDate!.year &&
                o.createdAt.month == _selectedDate!.month &&
                o.createdAt.day == _selectedDate!.day).toList();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date filter
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: widget.isDark
                          ? ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary))
                          : ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _selectedOrder = null;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.calendar,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Filter by Date (Optional)'
                            : DateFormat('MMM dd, yyyy')
                                .format(_selectedDate!),
                        style: GoogleFonts.alexandria(
                          fontSize: 13,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.lightText,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() {
                            _selectedDate = null;
                            _selectedOrder = null;
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Order dropdown
              DropdownButtonFormField<OrderEntity>(
                value: _selectedOrder,
                isExpanded: true,
                hint: Text(
                  filtered.isEmpty
                      ? 'No orders on this date'
                      : 'Select Order Number',
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
                dropdownColor: widget.isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                items: filtered
                    .map((o) => DropdownMenuItem<OrderEntity>(
                          value: o,
                          child: Text(
                            'Order #${o.orderNumber}',
                            style: GoogleFonts.alexandria(
                              fontSize: 14,
                              color: widget.isDark
                                  ? Colors.white
                                  : AppColors.lightText,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: filtered.isEmpty
                    ? null
                    : (v) => setState(() => _selectedOrder = v),
              ),
              // Download button
              if (_selectedOrder != null) ...[
                const SizedBox(height: 16),
                SettingsMenuTile(
                  icon: Iconsax.receipt_2,
                  label: 'Download Receipt',
                  isDark: widget.isDark,
                  trailing: Icon(
                    Icons.download_for_offline_rounded,
                    size: 20,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                  onTap: () async {
                    final pdf = await PdfService.generateOrderInvoice(
                        _selectedOrder!);
                    await Printing.layoutPdf(
                      onLayout: (f) async => pdf,
                      name: 'Invoice_${_selectedOrder!.orderNumber}',
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Center(
          child: Text(
            'No orders found',
            style: GoogleFonts.alexandria(
              fontSize: 12,
              color: widget.isDark
                  ? AppColors.darkSubtext
                  : AppColors.lightSubtext,
            ),
          ),
        ),
      );
}
