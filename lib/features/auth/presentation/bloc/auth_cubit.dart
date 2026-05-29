import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/features/auth/domain/usecases/login_usecase.dart';
import 'package:safe/features/auth/domain/usecases/register_usecase.dart';
import 'package:safe/features/auth/domain/usecases/forgot_password_usecases.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyResetOtpUseCase verifyResetOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyResetOtpUseCase,
    required this.resetPasswordUseCase,
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
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  }) async {
    emit(AuthLoading());

    final result = await registerUseCase.call(
      RegisterParams(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        bloodType: bloodType,
        medicalNotes: medicalNotes,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthSuccess(user)),
    );
  }

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    final result = await forgotPasswordUseCase.call(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthActionSuccess("Kode OTP telah dikirim ke email Anda")),
    );
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    emit(AuthLoading());
    final result = await verifyResetOtpUseCase.call(email, otp);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthActionSuccess("OTP valid")),
    );
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase.call(email, otp, newPassword);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthActionSuccess("Password berhasil diubah. Silakan login.")),
    );
  }
}
