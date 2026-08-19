// lib/features/profile/presentation/widgets/settings_widgets.dart
//
// All UI widgets for the Settings screen.
// The screen (settings_screen.dart) owns only state + BLoC wiring.
//
// DRY improvements vs original:
//   • AppCard         replaces raw Container+BoxDecoration on every card
//   • AppIconBox      replaces repeated icon-in-tinted-box pattern
//   • AppTextStyles   replaces inline GoogleFonts.alexandria calls
//   • AppGradientButton replaces duplicate gradient button construction
//   • AppConfirmDialog  replaces inline showDialog / AlertDialog
//   • AppSectionLabel(caps:true) replaces duplicate SettingsSectionLabel logic

import '../../../../core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/service/pdf_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/presentation/bloc/orders_bloc.dart';
import '../../../orders/presentation/bloc/orders_state.dart';
import '../../domain/entities/profile_entity.dart';

// ─── Section label ────────────────────────────────────────────────────────────

/// Thin backwards-compatible wrapper — delegates to AppSectionLabel(caps:true).
class SettingsSectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const SettingsSectionLabel({
    super.key,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) =>
      AppSectionLabel(text: label, isDark: isDark, caps: true);
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
    color: AppColors.primary.withValues(alpha: 0.1),
    child: Center(
      child: Text(
        (profile.fullName?.isNotEmpty == true
                ? profile.fullName![0]
                : profile.email?[0] ?? 'U')
            .toUpperCase(),
        style: GoogleFonts.pacifico(color: AppColors.primary, fontSize: 28),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isDark: isDark,
      child: Row(
        children: [
          // ── Avatar ───────────────────────────────────────────────
          GestureDetector(
            onTap: onPickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: profile.avatarUrl != null
                      ? AppNetworkImage(
                          url: profile.avatarUrl!,
                          width: 70,
                          height: 70,
                          radius: 35, // Circular
                          fallbackIcon: Icons.person,
                        )
                      : _avatarFallback(),
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
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Name / email / phone ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'User',
                  style: AppTextStyles.sectionTitle(isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? '',
                  style: AppTextStyles.subtitle(isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(profile.phone!, style: AppTextStyles.subtitle(isDark)),
                ],
              ],
            ),
          ),

          // ── Edit / spinner ────────────────────────────────────────
          if (isUpdating)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          else
            GestureDetector(
              onTap: onEditToggle,
              child: AppIconBox(
                icon: isEditing ? Icons.close_rounded : Iconsax.edit,
                borderRadius: 12,
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
    hintStyle: AppTextStyles.hint(isDark).copyWith(fontSize: 13),
    prefixIcon: Icon(
      icon,
      color: AppColors.primary.withValues(alpha: 0.7),
      size: 20,
    ),
    filled: true,
    fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) => AppCard(
    isDark: isDark,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Edit Profile', style: AppTextStyles.sectionTitle(isDark)),
        const SizedBox(height: 18),
        TextField(
          controller: nameCtrl,
          style: AppTextStyles.input,
          decoration: _deco('Full name', Iconsax.user),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneCtrl,
          style: AppTextStyles.input,
          keyboardType: TextInputType.phone,
          decoration: _deco('Phone number', Iconsax.call),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addrCtrl,
          style: AppTextStyles.input,
          maxLines: 2,
          decoration: _deco('Address', Icons.location_on_outlined),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.body(
                    isDark,
                  ).copyWith(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppGradientButton(
                label: 'Save',
                onPressed: onSave,
                verticalPadding: 13,
                borderRadius: 12,
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

  const SettingsMenuCard({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    isDark: isDark,
    padding: EdgeInsets.zero,
    borderRadius: 20,
    child: Column(
      children: List.generate(
        items.length,
        (i) => Column(
          children: [
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                indent: 56,
              ),
          ],
        ),
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
    leading: AppIconBox(icon: icon),
    title: Text(
      label,
      style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w500),
    ),
    trailing:
        trailing ??
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    leading: AppIconBox(icon: icon),
    title: Text(
      label,
      style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w500),
    ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primary,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

// ─── Logout button ────────────────────────────────────────────────────────────

class SettingsLogoutButton extends StatelessWidget {
  final bool isDark;
  const SettingsLogoutButton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => AppConfirmDialog.show(
        context,
        title: 'Sign Out?',
        message: 'Are you sure you want to sign out?',
        confirmLabel: 'Sign Out',
        confirmColor: AppColors.error,
        onConfirm: () =>
            context.read<AuthBloc>().add(const AuthSignOutRequested()),
      ),
      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
      label: Text(
        'Sign Out',
        style: AppTextStyles.buttonOutline.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

// ─── Receipt picker ───────────────────────────────────────────────────────────

class SettingsReceiptPicker extends StatefulWidget {
  final bool isDark;
  const SettingsReceiptPicker({super.key, required this.isDark});

  @override
  State<SettingsReceiptPicker> createState() => _SettingsReceiptPickerState();
}

class _SettingsReceiptPickerState extends State<SettingsReceiptPicker> {
  DateTime? _selectedDate;
  String? _selectedGroupKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is! OrdersLoaded || state.orders.isEmpty) {
          return _emptyCard();
        }
        final filtered = _selectedDate == null
            ? state.orders
            : state.orders
                  .where(
                    (o) =>
                        o.createdAt.year == _selectedDate!.year &&
                        o.createdAt.month == _selectedDate!.month &&
                        o.createdAt.day == _selectedDate!.day,
                  )
                  .toList();

        // ── Group orders by groupId (or fallback to id if null) ──
        final Map<String, List<OrderEntity>> groupedOrders = {};
        for (final o in filtered) {
          final key = o.groupId ?? o.id;
          groupedOrders.putIfAbsent(key, () => []).add(o);
        }
        
        // Find the selected group to pass to PDF generator
        final selectedGroup = _selectedGroupKey != null ? groupedOrders[_selectedGroupKey] : null;

        return AppCard(
          isDark: widget.isDark,
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateFilterRow(
                isDark: widget.isDark,
                selectedDate: _selectedDate,
                onDatePicked: (d) => setState(() {
                  _selectedDate = d;
                  _selectedGroupKey = null;
                }),
                onClear: () => setState(() {
                  _selectedDate = null;
                  _selectedGroupKey = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: groupedOrders.containsKey(_selectedGroupKey) ? _selectedGroupKey : null,
                isExpanded: true,
                hint: Text(
                  groupedOrders.isEmpty
                      ? 'No orders on this date'
                      : 'Select Order',
                  style: AppTextStyles.subtitle(widget.isDark),
                ),
                dropdownColor: widget.isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                items: groupedOrders.entries.map((entry) {
                  final key = entry.key;
                  final list = entry.value;
                  final isMulti = list.length > 1;
                  
                  String title = '';
                  final time = DateFormat('hh:mm a').format(list.first.createdAt);
                  if (isMulti) {
                    final orderNumbers = list.map((e) => '#${e.orderNumber}').join(', ');
                    title = 'Multi-Order: $orderNumbers • $time';
                  } else {
                    title = 'Order #${list.first.orderNumber} • $time';
                  }

                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      title,
                      style: AppTextStyles.body(widget.isDark),
                    ),
                  );
                }).toList(),
                onChanged: groupedOrders.isEmpty
                    ? null
                    : (v) => setState(() => _selectedGroupKey = v),
              ),
              if (selectedGroup != null && selectedGroup.isNotEmpty) ...[
                const SizedBox(height: 16),
                SettingsMenuTile(
                  icon: Iconsax.receipt_2,
                  label: 'Download Receipt',
                  isDark: widget.isDark,
                  trailing: Icon(
                    Icons.download_for_offline_rounded,
                    size: 20,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                  onTap: () async {
                    final pdf = await PdfService.generateMultiOrderInvoice(selectedGroup);
                    final nameSuffix = selectedGroup.length > 1 
                        ? 'Group_${selectedGroup.first.orderNumber}_Multi' 
                        : selectedGroup.first.orderNumber;
                    
                    await Printing.layoutPdf(
                      onLayout: (f) async => pdf,
                      name: 'Invoice_$nameSuffix',
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

  Widget _emptyCard() => AppCard(
    isDark: widget.isDark,
    padding: const EdgeInsets.all(16),
    borderRadius: 20,
    child: Center(
      child: Text(
        'No orders found',
        style: AppTextStyles.caption(widget.isDark),
      ),
    ),
  );
}

// ─── Date filter row (private) ────────────────────────────────────────────────

class _DateFilterRow extends StatelessWidget {
  final bool isDark;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onClear;

  const _DateFilterRow({
    required this.isDark,
    required this.selectedDate,
    required this.onDatePicked,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: isDark
                ? ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                    ),
                  )
                : ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
            child: child!,
          ),
        );
        if (picked != null) onDatePicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              selectedDate == null
                  ? 'Filter by Date (Optional)'
                  : DateFormat('MMM dd, yyyy').format(selectedDate!),
              style: AppTextStyles.body(isDark).copyWith(fontSize: 13),
            ),
            const Spacer(),
            if (selectedDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
