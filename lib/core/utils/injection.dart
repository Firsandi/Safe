import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:safe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:safe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:safe/features/auth/domain/repositories/auth_repository.dart';
import 'package:safe/features/auth/domain/usecases/login_usecase.dart';
import 'package:safe/features/auth/domain/usecases/register_usecase.dart';
import 'package:safe/features/auth/domain/usecases/forgot_password_usecases.dart';
import 'package:safe/features/auth/domain/usecases/verify_login_otp_usecase.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/core/localization/language_cubit.dart';

import 'package:safe/features/emergency/data/datasources/emergency_remote_data_source.dart';
import 'package:safe/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:safe/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:safe/features/emergency/domain/usecases/emergency_usecases.dart';
import 'package:safe/features/emergency/presentation/bloc/emergency_cubit.dart';

import 'package:safe/core/utils/session_manager.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLOC / CUBIT
  sl.registerFactory(() => AuthCubit(
        loginUseCase: sl(),
        registerUseCase: sl(),
        forgotPasswordUseCase: sl(),
        verifyResetOtpUseCase: sl(),
        resetPasswordUseCase: sl(),
        verifyLoginOtpUseCase: sl(),
      ));

  sl.registerFactory(() => LanguageCubit());

  sl.registerFactory(() => EmergencyCubit(
        getContactsUseCase: sl(),
        getPendingRequestsUseCase: sl(),
        searchUserUseCase: sl(),
        addContactUseCase: sl(),
        acceptRequestUseCase: sl(),
        rejectRequestUseCase: sl(),
        deleteContactUseCase: sl(),
      ));

  // USE CASES
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyResetOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyLoginOtpUseCase(sl()));
  sl.registerLazySingleton(() => GetContactsUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingRequestsUseCase(sl()));
  sl.registerLazySingleton(() => SearchUserUseCase(sl()));
  sl.registerLazySingleton(() => AddContactUseCase(sl()));
  sl.registerLazySingleton(() => AcceptRequestUseCase(sl()));
  sl.registerLazySingleton(() => RejectRequestUseCase(sl()));
  sl.registerLazySingleton(() => DeleteContactUseCase(sl()));

  // REPOSITORIES
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<EmergencyRepository>(
    () => EmergencyRepositoryImpl(remoteDataSource: sl()),
  );

  // DATA SOURCES
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<EmergencyRemoteDataSource>(
    () => EmergencyRemoteDataSourceImpl(dio: sl()),
  );

  // EXTERNAL
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://safe-backend-production-abb2.up.railway.app/', 
      // baseUrl: 'http://192.168.1.5:8080/',
      // baseUrl: 'http://10.0.2.2:8080/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Interceptor untuk menambahkan Bearer Token pada setiap request
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SessionManager.getToken();
        // Debug: print whether token exists (masked) to help debugging auth issues
        try {
          if (token == null) {
            debugPrint('Session token: MISSING');
          } else if (token.length > 8) {
            debugPrint('Session token: PRESENT (${token.substring(0,4)}...${token.substring(token.length-4)})');
          } else {
            debugPrint('Session token: PRESENT (short)');
          }
        } catch (_) {}
        if (token != null && token.isNotEmpty && token != 'logged_in') {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  sl.registerLazySingleton(() => dio);
}
