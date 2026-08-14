// lib/features/services/bloc/services_event.dart
import 'package:equatable/equatable.dart';

sealed class ServicesEvent extends Equatable {
  const ServicesEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load — fetch all active services from Supabase.
final class ServicesLoadRequested extends ServicesEvent {
  final bool forceRefresh;
  const ServicesLoadRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

/// Pull-to-refresh — reload from server, preserve current filter/search.
final class ServicesRefreshRequested extends ServicesEvent {
  const ServicesRefreshRequested();
}

/// Switch the active category chip.
/// Pass `'All Services'` to clear the filter.
final class ServicesFilterChanged extends ServicesEvent {
  final String category;
  const ServicesFilterChanged(this.category);
  @override
  List<Object> get props => [category];
}

/// Live search within the current category.
/// Pass an empty string to clear the search.
final class ServicesSearchChanged extends ServicesEvent {
  final String query;
  const ServicesSearchChanged(this.query);
  @override
  List<Object> get props => [query];
}
