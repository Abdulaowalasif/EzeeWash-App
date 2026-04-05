// lib/features/profile/screens/settings/address_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/responsive.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AddressModel {
  final String? id;
  final String label;
  final String address;
  final String? city;
  final bool isDefault;

  const AddressModel({this.id, required this.label, required this.address, this.city, this.isDefault = false});

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'] as String?,
    label: j['label'] as String? ?? 'Home',
    address: j['address'] as String? ?? '',
    city: j['city'] as String?,
    isDefault: j['is_default'] as bool? ?? false,
  );
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

abstract class AddressEvent {}
class AddressLoadRequested extends AddressEvent {}
class AddressSaveRequested extends AddressEvent {
  final AddressModel address;
  AddressSaveRequested(this.address);
}
class AddressDeleteRequested extends AddressEvent {
  final String id;
  AddressDeleteRequested(this.id);
}
class AddressSetDefault extends AddressEvent {
  final String id;
  AddressSetDefault(this.id);
}

abstract class AddressState {}
class AddressInitial extends AddressState {}
class AddressLoading extends AddressState {}
class AddressLoaded extends AddressState {
  final List<AddressModel> addresses;
  AddressLoaded(this.addresses);
}
class AddressError extends AddressState {
  final String message;
  AddressError(this.message);
}

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final SupabaseClient _client;
  AddressBloc(this._client) : super(AddressInitial()) {
    on<AddressLoadRequested>(_onLoad);
    on<AddressSaveRequested>(_onSave);
    on<AddressDeleteRequested>(_onDelete);
    on<AddressSetDefault>(_onSetDefault);
  }

  Future<void> _onLoad(AddressLoadRequested e, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      final data = await _client.from(AppConstants.addressesTable).select().eq('user_id', userId).order('created_at');
      emit(AddressLoaded((data as List).map((e) => AddressModel.fromJson(e)).toList()));
    } catch (e) { emit(AddressError(e.toString())); }
  }

  Future<void> _onSave(AddressSaveRequested e, Emitter<AddressState> emit) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (e.address.id != null) {
        await _client.from(AppConstants.addressesTable).update({'label': e.address.label, 'address': e.address.address, 'city': e.address.city}).eq('id', e.address.id!);
      } else {
        await _client.from(AppConstants.addressesTable).insert({'user_id': userId, 'label': e.address.label, 'address': e.address.address, 'city': e.address.city, 'is_default': false});
      }
      add(AddressLoadRequested());
    } catch (err) { emit(AddressError(err.toString())); }
  }

  Future<void> _onDelete(AddressDeleteRequested e, Emitter<AddressState> emit) async {
    try {
      await _client.from(AppConstants.addressesTable).delete().eq('id', e.id);
      add(AddressLoadRequested());
    } catch (err) { emit(AddressError(err.toString())); }
  }

  Future<void> _onSetDefault(AddressSetDefault e, Emitter<AddressState> emit) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from(AppConstants.addressesTable).update({'is_default': false}).eq('user_id', userId);
      await _client.from(AppConstants.addressesTable).update({'is_default': true}).eq('id', e.id);
      add(AddressLoadRequested());
    } catch (err) { emit(AddressError(err.toString())); }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AddressBloc(Supabase.instance.client)..add(AddressLoadRequested()),
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
  void dispose() { _streetCtrl.dispose(); _cityCtrl.dispose(); super.dispose(); }

  void _save() {
    if (_streetCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) return;
    context.read<AddressBloc>().add(AddressSaveRequested(AddressModel(id: _editing?.id, label: _type, address: _streetCtrl.text.trim(), city: _cityCtrl.text.trim())));
    _streetCtrl.clear(); _cityCtrl.clear();
    setState(() { _type = 'Home'; _editing = null; });
    FocusScope.of(context).unfocus();
  }

  void _startEdit(AddressModel a) {
    setState(() { _editing = a; _type = a.label; _streetCtrl.text = a.address; _cityCtrl.text = a.city ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _GradientAppBar(title: 'Manage Addresses'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 10),

              // Form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_editing != null ? 'Update Address' : 'Add New Address',
                      style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightText)),
                  const SizedBox(height: 16),

                  // Type chips
                  Row(children: ['Home', 'Work', 'Other'].map((t) {
                    final sel = _type == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.gradient : null,
                            color: sel ? null : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(t, style: GoogleFonts.alexandria(fontSize: 12, color: sel ? Colors.white : (isDark ? Colors.grey : Colors.black87), fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 16),

                  _TextField(ctrl: _streetCtrl, hint: 'Street Address', icon: Icons.map_outlined, isDark: isDark),
                  const SizedBox(height: 12),
                  _TextField(ctrl: _cityCtrl, hint: 'City, Division, ZIP Code', icon: Icons.location_city_rounded, isDark: isDark),
                  const SizedBox(height: 20),

                  Row(children: [
                    if (_editing != null) ...[
                      Expanded(child: OutlinedButton(
                        onPressed: () => setState(() { _editing = null; _streetCtrl.clear(); _cityCtrl.clear(); _type = 'Home'; }),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Cancel', style: GoogleFonts.alexandria(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: Container(
                      decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: Icon(_editing != null ? Icons.update_rounded : Icons.add_rounded, color: Colors.white, size: 18),
                        label: Text(_editing != null ? 'Update' : 'Add Address', style: GoogleFonts.alexandria(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    )),
                  ]),
                ]),
              ),

              const SizedBox(height: 28),
              Text('Saved Addresses', style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightText)),
              const SizedBox(height: 14),

              BlocBuilder<AddressBloc, AddressState>(builder: (context, state) {
                if (state is AddressLoading) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                if (state is AddressError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(state.message, style: GoogleFonts.alexandria(color: AppColors.error))));
                if (state is AddressLoaded) {
                  if (state.addresses.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('No addresses saved yet.', style: GoogleFonts.alexandria(color: Colors.grey))));
                  return Column(children: state.addresses.map((a) => _AddressCard(
                    address: a, isDark: isDark,
                    onEdit: () => _startEdit(a),
                    onDelete: () => context.read<AddressBloc>().add(AddressDeleteRequested(a.id!)),
                    onSetDefault: () => context.read<AddressBloc>().add(AddressSetDefault(a.id!)),
                  )).toList());
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Sub widgets ──────────────────────────────────────────────────────────────

class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _GradientAppBar({required this.title});
  @override Size get preferredSize => const Size.fromHeight(100);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 10, Responsive.horizontalPadding(context), 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22)),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.alexandria(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool isDark;
  const _TextField({required this.ctrl, required this.hint, required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: GoogleFonts.alexandria(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.lightBackground,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isDark;
  final VoidCallback onEdit, onDelete, onSetDefault;
  const _AddressCard({required this.address, required this.isDark, required this.onEdit, required this.onDelete, required this.onSetDefault});

  IconData get _icon => address.label == 'Work' ? Icons.work_rounded : address.label == 'Other' ? Icons.location_on_rounded : Icons.home_rounded;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: address.isDefault ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder), width: address.isDefault ? 2 : 1),
      boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 14, offset: const Offset(0, 5))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 12),
        Text(address.label, style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.lightText)),
        const Spacer(),
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22), visualDensity: VisualDensity.compact),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20), visualDensity: VisualDensity.compact),
      ]),
      const SizedBox(height: 12),
      Text('${address.address}${address.city != null ? '\n${address.city}' : ''}',
          style: GoogleFonts.alexandria(fontSize: 14, height: 1.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: address.isDefault
            ? Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.4))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            const SizedBox(width: 8),
            Text('Default Address', style: GoogleFonts.alexandria(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        )
            : OutlinedButton(
          onPressed: onSetDefault,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text('Set as Default', style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    ]),
  );
}