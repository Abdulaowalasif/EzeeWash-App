// lib/features/address/presentation/bloc/address_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AddressModel {
  final String? id;
  final String label;
  final String address;
  final String? city;
  final bool isDefault;

  const AddressModel({
    this.id,
    required this.label,
    required this.address,
    this.city,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
        id: j['id'] as String?,
        label: j['label'] as String? ?? 'Home',
        address: j['address'] as String? ?? '',
        city: j['city'] as String?,
        isDefault: j['is_default'] as bool? ?? false,
      );
}

// ─── Events ───────────────────────────────────────────────────────────────────

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

// ─── States ───────────────────────────────────────────────────────────────────

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

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final SupabaseClient _client;

  AddressBloc(this._client) : super(AddressInitial()) {
    on<AddressLoadRequested>(_onLoad);
    on<AddressSaveRequested>(_onSave);
    on<AddressDeleteRequested>(_onDelete);
    on<AddressSetDefault>(_onSetDefault);
  }

  Future<void> _onLoad(
    AddressLoadRequested e,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      final data = await _client
          .from(AppConstants.addressesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at');
      emit(AddressLoaded(
        (data as List).map((e) => AddressModel.fromJson(e)).toList(),
      ));
    } catch (e) {
      emit(AddressError(e.toString()));
    }
  }

  Future<void> _onSave(
    AddressSaveRequested e,
    Emitter<AddressState> emit,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (e.address.id != null) {
        await _client.from(AppConstants.addressesTable).update({
          'label': e.address.label,
          'address': e.address.address,
          'city': e.address.city,
        }).eq('id', e.address.id!);
      } else {
        await _client.from(AppConstants.addressesTable).insert({
          'user_id': userId,
          'label': e.address.label,
          'address': e.address.address,
          'city': e.address.city,
          'is_default': false,
        });
      }
      add(AddressLoadRequested());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onDelete(
    AddressDeleteRequested e,
    Emitter<AddressState> emit,
  ) async {
    try {
      await _client
          .from(AppConstants.addressesTable)
          .delete()
          .eq('id', e.id);
      add(AddressLoadRequested());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onSetDefault(
    AddressSetDefault e,
    Emitter<AddressState> emit,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': false})
          .eq('user_id', userId);
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': true})
          .eq('id', e.id);
      add(AddressLoadRequested());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }
}
