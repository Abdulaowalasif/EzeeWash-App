// lib/core/di/injection_container.dart
import 'package:ezzewash/features/promos/domain/usecases/watch_promo_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecase/change_password_usecase.dart';
import '../../features/auth/domain/usecase/current_user_usecase.dart';
import '../../features/auth/domain/usecase/sign_in_usecase.dart';
import '../../features/auth/domain/usecase/sign_out_usecase.dart';
import '../../features/auth/domain/usecase/sign_up_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repositories.dart';
import '../../features/notifications/domain/usecases/notification_usecase.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecase.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/promos/data/datasources/promo_remote_datasource.dart';
import '../../features/promos/data/repositories/promo_repository_impl.dart';
import '../../features/promos/domain/repositories/promo_repository.dart';
import '../../features/promos/presentation/bloc/promo_bloc.dart';
import '../../features/services/data/datasources/service_remote_datasource.dart';
import '../../features/services/data/repositories/service_repository_impl.dart';
import '../../features/services/domain/repositories/service_repository.dart';
import '../../features/services/domain/usecases/service_usecase.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';
import '../../features/store/data/datasources/stores_remote_datasouce.dart';
import '../../features/store/data/repositories/stores_repository_impl.dart';
import '../../features/store/domain/repositories/store_repository.dart';
import '../../features/store/domain/usecases/stores_usecase.dart';
import '../../features/store/presentation/bloc/store_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ─── AUTH ──────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => AuthBloc(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      signOutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      changePasswordUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl())); // Added

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // ─── SERVICES ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ServicesRemoteDataSource>(
    () => ServicesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ServicesRepository>(
    () => ServicesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAllServicesUseCase(sl()));
  sl.registerLazySingleton(() => GetServicesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetServiceByIdUseCase(sl()));

  sl.registerLazySingleton(
    () => ServicesBloc(
      getAllServicesUseCase: sl(),
      getServicesByCategoryUseCase: sl(),
      getServiceByIdUseCase: sl(),
    ),
  );

  // ─── STORES ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<StoresRemoteDataSource>(
    () => StoresRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<StoresRepository>(() => StoresRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAllStoresUseCase(sl()));
  sl.registerLazySingleton(() => GetStoreByIdUseCase(sl()));

  sl.registerLazySingleton(
    () => StoresBloc(getAllStoresUseCase: sl(), getStoreByIdUseCase: sl()),
  );

  // ─── ORDERS ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(remoteDataSource: sl(), client: sl()),
  );
  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl())); // ← new

  sl.registerFactory(
    () => OrdersBloc(
      getOrdersUseCase: sl(),
      getOrderByIdUseCase: sl(),
      placeOrderUseCase: sl(),
      cancelOrderUseCase: sl(),
      // ← new
      client: sl(),
    ),
  );

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl(), client: sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));

  sl.registerFactory(
    () => NotificationsBloc(
      getNotificationsUseCase: sl(),
      markReadUseCase: sl(),
      markAllReadUseCase: sl(),
      client: sl<SupabaseClient>(),
    ),
  );

  // ─── PROFILE ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl(), client: sl()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAvatarUseCase(sl()));

  sl.registerFactory(
    () => ProfileBloc(
      getProfileUseCase: sl(),
      updateProfileUseCase: sl(),
      updateAvatarUseCase: sl(),
    ),
  );

  // ─── PROMOS ───────────────────────────────────────────────────────────────

  // 1. Data Source
  sl.registerLazySingleton<PromoRemoteDataSource>(
    () => PromoRemoteDataSourceImpl(sl()),
  );

  // 2. Repository
  sl.registerLazySingleton<PromoRepository>(() => PromoRepositoryImpl(sl()));

  // 3. Use Cases
  sl.registerLazySingleton(() => WatchPromosUseCase(sl()));

  // 4. BLoC (Using registerFactory because UI should usually get a fresh BLoC instance)
  sl.registerFactory(() => PromoBloc(watchPromosUseCase: sl()));
}
