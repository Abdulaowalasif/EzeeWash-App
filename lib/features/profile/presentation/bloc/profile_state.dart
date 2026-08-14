// lib/features/profile/bloc/profile_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/profile_entity.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

/// Before the first [ProfileLoadRequested] completes.
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Fetching profile — show a loading indicator.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully and ready for display.
final class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  const ProfileLoaded(this.profile);
  @override
  List<Object> get props => [profile];
}

/// A save (text fields or avatar) is in progress.
/// [profile] holds the stale data so the UI keeps rendering.
final class ProfileUpdating extends ProfileState {
  final ProfileEntity profile;
  const ProfileUpdating(this.profile);
  @override
  List<Object> get props => [profile];
}

/// Load or save failed. [message] is safe to display.
/// [profile] is non-null when the error occurred during an update
/// (avatar/text save) — the builder uses it to keep showing content.
final class ProfileError extends ProfileState {
  final String message;
  final ProfileEntity? profile;
  const ProfileError({required this.message, this.profile});
  @override
  List<Object?> get props => [message, profile];
}
