import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/features/auth/domain/usecases/login_usecase.dart';
import 'package:safe/features/auth/domain/usecases/register_usecase.dart';
import 'package:safe/features/auth/domain/usecases/forgot_password_usecases.dart';
import 'package:safe/features/auth/domain/usecases/verify_login_otp_usecase.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyResetOtpUseCase verifyResetOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyLoginOtpUseCase verifyLoginOtpUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyResetOtpUseCase,
    required this.resetPasswordUseCase,
    required this.verifyLoginOtpUseCase,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    // Coba ambil device_token
    final deviceToken = await SessionManager.getDeviceToken();

    final result = await loginUseCase.call(
      LoginParams(email: email, password: password, deviceToken: deviceToken),
    );

    result.fold(
      (failure) {
        if (failure is OtpRequiredFailure) {
          emit(AuthOtpRequired(email, failure.message));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        // Jika bypass berhasil
        if (user.token != null) {
          await SessionManager.saveSession(
            token: user.token!,
            userData: {
              'user_id': user.userId,
              'email': user.email,
              'name': user.name,
              'phone_number': user.phoneNumber,
              'blood_type': user.bloodType,
              'medical_notes': user.medicalNotes,
              'profile_image': user.profileImage,
            },
          );
        }
        emit(AuthSuccess(user));
      },
    );
  }

  Future<void> verifyLoginOtp(String email, String otp) async {
    emit(AuthLoading());

    final result = await verifyLoginOtpUseCase.call(email, otp);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) async {
        if (user.token != null) {
          await SessionManager.saveSession(
            token: user.token!,
            userData: {
              'user_id': user.userId,
              'email': user.email,
              'name': user.name,
              'phone_number': user.phoneNumber,
              'blood_type': user.bloodType,
              'medical_notes': user.medicalNotes,
              'profile_image': user.profileImage,
            },
          );
        }
        if (user.deviceToken != null) {
          await SessionManager.saveDeviceToken(user.deviceToken!);
        }
        emit(AuthSuccess(user));
      },
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
