import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/features/auth/domain/usecases/login_usecase.dart';
import 'package:safe/features/auth/domain/usecases/register_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final result = await loginUseCase.call(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> register({
    required String nama,
    required String nomorHp,
    required String email,
    required String password,
    String? golDarah,
    String? catatanMedis,
  }) async {
    emit(AuthLoading());

    final result = await registerUseCase.call(
      RegisterParams(
        nama: nama,
        nomorHp: nomorHp,
        email: email,
        password: password,
        golDarah: golDarah,
        catatanMedis: catatanMedis,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }
}
