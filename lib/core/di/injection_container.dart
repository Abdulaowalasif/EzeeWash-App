// lib/core/di/injection_container.dart

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecase/current_user_usecase.dart';
import '../../features/auth/domain/usecase/sign_in_usecase.dart';
import '../../features/auth/domain/usecase/sign_out_usecase.dart';
import '../../features/auth/domain/usecase/sign_up_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

import '../../features/services/data/datasources/service_remote_datasource.dart';
import '../../features/services/data/repositories/service_repository_impl.dart';
import '../../features/services/domain/repositories/service_repository.dart';
import '../../features/services/domain/usecases/service_usecase.dart';
import '../../features/services/presentation/bloc/service_bloc.dart';

import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecase.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';

import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  /// =================== External ===================
  sl.registerLazySingleton<SupabaseClient>(
        () => Supabase.instance.client,
  );

  /// =================== AUTH ===================
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
  sl.registerLazySingleton(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<AuthBloc>(
        () =>
        AuthBloc(
          signInUseCase: sl<SignInUseCase>(),
          signUpUseCase: sl<SignUpUseCase>(),
          signOutUseCase: sl<SignOutUseCase>(),
          getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
          authRepository: sl<AuthRepository>(),
        ),
  );

  /// =================== SERVICES ===================
  sl.registerLazySingleton<ServicesRemoteDataSource>(
        () => ServicesRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<ServicesRemoteDataSource>()),
  );
  sl.registerLazySingleton(() =>
      GetAllServicesUseCase(sl<ServicesRepository>()));
  sl.registerLazySingleton(() =>
      GetServicesByCategoryUseCase(sl<ServicesRepository>()));
  sl.registerLazySingleton(() =>
      GetServiceByIdUseCase(sl<ServicesRepository>()));
  sl.registerFactory(
        () =>
        ServicesBloc(
          getAllServicesUseCase: sl<GetAllServicesUseCase>(),
          getServicesByCategoryUseCase: sl<GetServicesByCategoryUseCase>(),
          getServiceByIdUseCase: sl<GetServiceByIdUseCase>(),
        ),
  );

  /// =================== PROFILE ===================
  sl.registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
        () =>
        ProfileRepositoryImpl(
          remoteDataSource: sl<ProfileRemoteDataSource>(),
          client: sl<SupabaseClient>(),
        ),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<ProfileRepository>()));
  sl.registerLazySingleton(() => UpdateAvatarUseCase(sl<ProfileRepository>()));
  sl.registerFactory(
        () =>
        ProfileBloc(
          getProfileUseCase: sl<GetProfileUseCase>(),
          updateProfileUseCase: sl<UpdateProfileUseCase>(),
          updateAvatarUseCase: sl<UpdateAvatarUseCase>(),
        ),
  );

  /// =================== ORDERS ===================
  sl.registerLazySingleton<OrdersRemoteDataSource>(
        () => OrdersRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
        () =>
        OrdersRepositoryImpl(
          remoteDataSource: sl<OrdersRemoteDataSource>(),
          client: sl<SupabaseClient>(),
        ),
  );
  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => GetOrderByIdUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl<OrdersRepository>()));
  sl.registerFactory(
        () =>
        OrdersBloc(
          getOrdersUseCase: sl<GetOrdersUseCase>(),
          getOrderByIdUseCase: sl<GetOrderByIdUseCase>(),
          placeOrderUseCase:sl<PlaceOrderUseCase>(),
          client:sl<SupabaseClient>(),

        ),
  );

  /// =================== NOTIFICATIONS ===================
  sl.registerFactory(
        () => NotificationsBloc(sl<SupabaseClient>()),
  );
}