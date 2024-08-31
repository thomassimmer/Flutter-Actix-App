import 'package:bloc/bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/validate_otp_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:universal_io/io.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase = GetIt.instance<LoginUseCase>();
  final SignupUseCase signupUseCase = GetIt.instance<SignupUseCase>();
  final GenerateOtpConfigUseCase generateOtpConfigUseCase =
      GetIt.instance<GenerateOtpConfigUseCase>();
  final VerifyOtpUseCase verifyOtpUseCase = GetIt.instance<VerifyOtpUseCase>();
  final ValidateOtpUsecase validateOtpUsecase =
      GetIt.instance<ValidateOtpUsecase>();
  final DisableOtpUseCase disableOtpUseCase =
      GetIt.instance<DisableOtpUseCase>();

  AuthBloc() : super(AuthLoading()) {
    on<AuthInitRequested>(_onInitializeAuth);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthOtpGenerationRequested>(_onOtpGenerationRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthOtpValidationRequested>(_onOtpValidationRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // Function to check initial authentication state
  Future<void> _onInitializeAuth(
      AuthInitRequested event, Emitter<AuthState> emit) async {
    final result = await TokenStorage().getAccessToken();

    if (result == null) {
      emit(AuthUnauthenticated());
    } else {
      emit(AuthAuthenticatedAfterLogin(
        hasValidatedOtp: false,
      ));
    }
  }

  void _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // We use the device locale by default on signup
    final result = await signupUseCase.call(
        event.username, event.password, Platform.localeName, event.theme);

    await result.fold(
      (userToken) async {
        // Store tokens securely after successful login
        await TokenStorage().saveTokens(
          userToken.accessToken,
          userToken.refreshToken,
          userToken.expiresIn,
        );

        emit(AuthAuthenticatedAfterRegistration(
            recoveryCodes: userToken.recoveryCodes, hasVerifiedOtp: false));
      },
      (failure) {
        emit(AuthFailure(message: failure.message));
      },
    );
  }

  void _onOtpGenerationRequested(
      AuthOtpGenerationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await generateOtpConfigUseCase.call();

    result.fold(
      (generatedOtpConfig) => emit(AuthOtpVerify(
          otpAuthUrl: generatedOtpConfig.otpAuthUrl,
          otpBase32: generatedOtpConfig.otpBase32)),
      (failure) => emit(AuthFailure(message: failure.message)),
    );
  }

  void _onOtpVerificationRequested(
      AuthOtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await verifyOtpUseCase.call(event.code);

    result.fold(
      (_) => emit(AuthAuthenticatedAfterRegistration(hasVerifiedOtp: true)),
      (failure) => emit(AuthOtpVerify(
          message: failure.message,
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32)),
    );
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final loginResult = await loginUseCase.call(event.username, event.password);

    await loginResult.fold(
      (userOrUserId) async {
        await userOrUserId.fold(
          (userToken) async {
            // Store tokens securely after successful login
            await TokenStorage().saveTokens(
              userToken.accessToken,
              userToken.refreshToken,
              userToken.expiresIn,
            );

            emit(AuthAuthenticatedAfterLogin(
              hasValidatedOtp: false,
            ));
          },
          (userId) {
            emit(AuthOtpValidate(userId: userId));
          },
        );
      },
      (failure) {
        emit(AuthFailure(message: failure.message));
      },
    );
  }

  void _onOtpValidationRequested(
      AuthOtpValidationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await validateOtpUsecase.call(event.userId, event.code);

    result.fold(
      (userTokenModel) =>
          emit(AuthAuthenticatedAfterLogin(hasValidatedOtp: true)),
      (failure) =>
          emit(AuthOtpValidate(message: failure.message, userId: event.userId)),
    );
  }

  void _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await TokenStorage().deleteTokens();

    emit(AuthUnauthenticated());
  }
}
