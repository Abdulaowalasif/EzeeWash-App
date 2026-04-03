// lib/features/address/presentation/screens/address_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/address_bloc.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) =>
            AddressBloc(Supabase.instance.client)..add(AddressLoadRequested()),
        child: const _AddressView(),
      );
}

class _AddressView extends StatefulWidget {
  const _AddressView();

  @override
  State<_AddressView> createState() => _AddressViewState();
}

class _AddressViewState extends State<_AddressView> {
  String _type = 'Home';
  AddressModel? _editing;
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_streetCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
      return;
    }
    context.read<AddressBloc>().add(
          AddressSaveRequested(AddressModel(
            id: _editing?.id,
            label: _type,
            address: _streetCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
          )),
        );
    _streetCtrl.clear();
    _cityCtrl.clear();
    setState(() {
      _type = 'Home';
      _editing = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _startEdit(AddressModel a) {
    setState(() {
      _editing = a;
      _type = a.label;
      _streetCtrl.text = a.address;
      _cityCtrl.text = a.city ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: GradientAppBar(title: 'Manage Addresses'),
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _AddressForm(
                  isDark: isDark,
                  type: _type,
                  editing: _editing,
                  streetCtrl: _streetCtrl,
                  cityCtrl: _cityCtrl,
                  onTypeChanged: (t) => setState(() => _type = t),
                  onSave: _save,
                  onCancel: () => setState(() {
                    _editing = null;
                    _streetCtrl.clear();
                    _cityCtrl.clear();
                    _type = 'Home';
                  }),
                ),
                const SizedBox(height: 28),
                AppSectionLabel(text: 'Saved Addresses', isDark: isDark),
                const SizedBox(height: 14),
                BlocBuilder<AddressBloc, AddressState>(
                  builder: (context, state) {
                    if (state is AddressLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: AppLoadingIndicator(),
                      );
                    }
                    if (state is AddressError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            state.message,
                            style: GoogleFonts.alexandria(
                                color: AppColors.error),
                          ),
                        ),
                      );
                    }
                    if (state is AddressLoaded) {
                      if (state.addresses.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No addresses saved yet.'),
                          ),
                        );
                      }
                      return Column(
                        children: state.addresses
                            .map((a) => _AddressCard(
                                  address: a,
                                  isDark: isDark,
                                  onEdit: () => _startEdit(a),
                                  onDelete: () => context
                                      .read<AddressBloc>()
                                      .add(AddressDeleteRequested(a.id!)),
                                  onSetDefault: () => context
                                      .read<AddressBloc>()
                                      .add(AddressSetDefault(a.id!)),
                                ))
                            .toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form card ────────────────────────────────────────────────────────────────

class _AddressForm extends StatelessWidget {
  final bool isDark;
  final String type;
  final AddressModel? editing;
  final TextEditingController streetCtrl;
  final TextEditingController cityCtrl;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _AddressForm({
    required this.isDark,
    required this.type,
    required this.editing,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.onTypeChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editing != null ? 'Update Address' : 'Add New Address',
            style: GoogleFonts.alexandria(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 16),
          // Type chips
          Row(
            children: ['Home', 'Work', 'Other'].map((t) {
              final sel = type == t;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.gradient : null,
                      color: sel
                          ? null
                          : (isDark
                              ? Colors.white10
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.alexandria(
                        fontSize: 12,
                        color: sel
                            ? Colors.white
                            : (isDark ? Colors.grey : Colors.black87),
                        fontWeight: sel
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          AppOutlinedInput(
            controller: streetCtrl,
            hint: 'Street Address',
            icon: Icons.map_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          AppOutlinedInput(
            controller: cityCtrl,
            hint: 'City, Division, ZIP Code',
            icon: Icons.location_city_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (editing != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? Colors.white24
                            : Colors.grey.shade300,
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.alexandria(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppGradientButton(
                  label: editing != null ? 'Update' : 'Add Address',
                  icon: editing != null
                      ? Icons.update_rounded
                      : Icons.add_rounded,
                  onPressed: onSave,
                  borderRadius: 12,
                  verticalPadding: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isDark;
  final VoidCallback onEdit, onDelete, onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  IconData get _icon => address.label == 'Work'
      ? Icons.work_rounded
      : address.label == 'Other'
          ? Icons.location_on_rounded
          : Icons.home_rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: address.isDefault ? 2 : 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                address.label,
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 22),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${address.address}${address.city != null ? '\n${address.city}' : ''}',
            style: GoogleFonts.alexandria(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: address.isDefault
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Default Address',
                          style: GoogleFonts.alexandria(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : OutlinedButton(
                    onPressed: onSetDefault,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Set as Default',
                      style: GoogleFonts.alexandria(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
