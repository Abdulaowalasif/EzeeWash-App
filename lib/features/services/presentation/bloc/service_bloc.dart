// lib/features/services/bloc/services_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ezeewash/features/services/presentation/bloc/service_event.dart';
import 'package:ezeewash/features/services/presentation/bloc/service_state.dart';

import '../../../../core/utils/usecase.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/service_usecase.dart';



class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final GetAllServicesUseCase getAllServicesUseCase;
  final GetServicesByCategoryUseCase getServicesByCategoryUseCase;
  final GetServiceByIdUseCase getServiceByIdUseCase;

  List<ServiceEntity> _allServices = [];

  ServicesBloc({
    required this.getAllServicesUseCase,
    required this.getServicesByCategoryUseCase,
    required this.getServiceByIdUseCase,
  }) : super(const ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServicesFilterChanged>(_onFilter);
    on<ServicesSearchChanged>(_onSearch);
  }

  Future<void> _onLoad(ServicesLoadRequested event, Emitter<ServicesState> emit) async {
    emit(const ServicesLoading());
    final result = await getAllServicesUseCase(const NoParams());
    result.fold(
          (failure) => emit(ServicesError(failure.message)),
          (services) {
        _allServices = services;
        emit(ServicesLoaded(
          services: _allServices,
          filtered: _allServices,
          selectedCategory: 'All Services',
          searchQuery: '',
        ));
      },
    );
  }

  void _onFilter(ServicesFilterChanged event, Emitter<ServicesState> emit) {
    if (state is! ServicesLoaded) return;
    final cur = state as ServicesLoaded;
    final filtered = event.category == 'All Services'
        ? _allServices
        : _allServices.where((s) => s.category == event.category).toList();
    emit(cur.copyWith(filtered: filtered, selectedCategory: event.category, searchQuery: ''));
  }

  void _onSearch(ServicesSearchChanged event, Emitter<ServicesState> emit) {
    if (state is! ServicesLoaded) return;
    final cur = state as ServicesLoaded;
    final base = cur.selectedCategory == 'All Services'
        ? _allServices
        : _allServices.where((s) => s.category == cur.selectedCategory).toList();
    final filtered = event.query.isEmpty
        ? base
        : base.where((s) =>
    s.title.toLowerCase().contains(event.query.toLowerCase()) ||
        (s.description?.toLowerCase().contains(event.query.toLowerCase()) ?? false)).toList();
    emit(cur.copyWith(filtered: filtered, searchQuery: event.query));
  }
}