// lib/features/profile/bloc/profile_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:ezzewash/features/profile/presentation/bloc/profile_event.dart';
import 'package:ezzewash/features/profile/presentation/bloc/profile_state.dart';
import '../../domain/usecases/profile_usecase.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;

  ProfileBloc({
    required this.getProfileUseCase,
    required this.updateProfileUseCase,
    required this.updateAvatarUseCase,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileAvatarUpdateRequested>(_onAvatarUpdate);
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!event.forceRefresh && state is ProfileLoaded) {
      // Handled by cache
    } else {
      emit(const ProfileLoading());
    }
    final result = await getProfileUseCase(
      GetProfileParams(forceRefresh: event.forceRefresh),
    );
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final current = (state as ProfileLoaded).profile;
    emit(ProfileUpdating(current));

    final result = await updateProfileUseCase(
      UpdateProfileParams(
        fullName: event.fullName,
        phone: event.phone,
        address: event.address,
        city: event.city,
      ),
    );
    result.fold(
      (failure) =>
          emit(ProfileError(message: failure.message, profile: current)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onAvatarUpdate(
    ProfileAvatarUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final current = (state as ProfileLoaded).profile;
    emit(ProfileUpdating(current));

    final result = await updateAvatarUseCase(
      UpdateAvatarParams(event.imageFile),
    );
    result.fold(
      (failure) =>
          emit(ProfileError(message: failure.message, profile: current)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }
}
