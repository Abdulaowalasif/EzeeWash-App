// lib/features/profile/presentation/bloc/address_bloc.dart
import 'package:bloc/bloc.dart';
import '../../data/datasources/address_remote_datasource.dart';
import 'address_event.dart';
import 'address_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Still needed just for user ID unless we pass it

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRemoteDataSource _dataSource;
  final SupabaseClient _client; // Keeping for auth context

  AddressBloc(this._dataSource, this._client) : super(AddressInitial()) {
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
      final addresses = await _dataSource.getAddresses(userId);
      emit(AddressLoaded(addresses));
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
        await _dataSource.updateAddress(e.address);
      } else {
        await _dataSource.insertAddress(userId, e.address);
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
      await _dataSource.deleteAddress(e.id);
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
      await _dataSource.setDefaultAddress(userId, e.id);
      add(AddressLoadRequested());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }
}

