// lib/features/services/bloc/services_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/service_entity.dart';

sealed class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

/// No load has been attempted yet.
final class ServicesInitial extends ServicesState {
  const ServicesInitial();
}

/// Fetching services from Supabase — show a shimmer/spinner.
final class ServicesLoading extends ServicesState {
  const ServicesLoading();
}

/// Services loaded. [filtered] is what the UI renders;
/// [services] is the full unfiltered master list.
final class ServicesLoaded extends ServicesState {
  final List<ServiceEntity> services;
  final List<ServiceEntity> filtered;
  final String selectedCategory;
  final String searchQuery;

  const ServicesLoaded({
    required this.services,
    required this.filtered,
    required this.selectedCategory,
    required this.searchQuery,
  });

  /// Unique categories extracted from the master list, prepended with "All Services".
  List<String> get categories {
    final cats = services.map((s) => s.category).toSet().toList()..sort();
    return ['All Services', ...cats];
  }

  bool get isSearching => searchQuery.isNotEmpty;

  ServicesLoaded copyWith({
    List<ServiceEntity>? services,
    List<ServiceEntity>? filtered,
    String? selectedCategory,
    String? searchQuery,
  }) =>
      ServicesLoaded(
        services: services ?? this.services,
        filtered: filtered ?? this.filtered,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [services, filtered, selectedCategory, searchQuery];
}

/// The load failed. [message] is safe to show in the UI.
final class ServicesError extends ServicesState {
  final String message;
  const ServicesError(this.message);
  @override
  List<Object> get props => [message];
}