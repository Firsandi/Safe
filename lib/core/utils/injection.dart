import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:safe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:safe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:safe/features/auth/domain/repositories/auth_repository.dart';
import 'package:safe/features/auth/domain/usecases/login_usecase.dart';
import 'package:safe/features/auth/domain/usecases/register_usecase.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/core/localization/language_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl(),
        registerUseCase: sl(),
      ));

  sl.registerFactory(() => LanguageCubit());

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton(() => Dio());
}
