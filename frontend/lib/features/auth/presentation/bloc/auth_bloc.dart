import 'package:bloc/bloc.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/otp_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final OtpUseCase otpUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.otpUseCase,
  }) : super(AuthUnauthenticated()) {
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthOtpGenerationRequested>(_onOtpGenerationRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthOtpValidationRequested>(_onOtpValidationRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await signupUseCase.signup(event.username, event.password);

    result.fold(
      (userTokenEntity) => emit(AuthAuthenticatedAfterRegistration(
          accessToken: userTokenEntity.accessToken,
          refreshToken: userTokenEntity.refreshToken,
          expiresIn: userTokenEntity.expiresIn,
          recoveryCodes: userTokenEntity.recoveryCodes,
          hasVerifiedOtp: false)),
      (failure) => emit(AuthFailure(message: failure.message)),
    );
  }

  void _onOtpGenerationRequested(
      AuthOtpGenerationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.generateOtp(event.accessToken);

    result.fold(
      (otpGenerationEntity) => emit(AuthOtpVerify(
          accessToken: event.accessToken,
          refreshToken: event.refreshToken,
          expiresIn: event.expiresIn,
          otpAuthUrl: otpGenerationEntity.otpAuthUrl,
          otpBase32: otpGenerationEntity.otpBase32)),
      (failure) => emit(AuthFailure(message: failure.message)),
    );
  }

  void _onOtpVerificationRequested(
      AuthOtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.verifyOtp(event.accessToken, event.code);

    result.fold(
      (_) => emit(AuthAuthenticatedAfterRegistration(
          accessToken: event.accessToken,
          refreshToken: event.refreshToken,
          expiresIn: event.expiresIn,
          hasVerifiedOtp: true)),
      (failure) => emit(AuthOtpVerify(
          message: failure.message,
          accessToken: event.accessToken,
          refreshToken: event.refreshToken,
          expiresIn: event.expiresIn,
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32)),
    );
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase.login(event.username, event.password);

    result.fold((userOrUserId) {
      userOrUserId.fold(
          (userTokenEntity) => emit(AuthAuthenticatedAfterLogin(
              accessToken: userTokenEntity.accessToken,
              refreshToken: userTokenEntity.refreshToken,
              expiresIn: userTokenEntity.expiresIn,
              hasValidatedOtp: false)),
          (userId) => emit(AuthOtpValidate(userId: userId)));
    }, (failure) => emit(AuthFailure(message: failure.message)));
  }

  void _onOtpValidationRequested(
      AuthOtpValidationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.validateOtp(event.userId, event.code);

    result.fold(
      (userTokenModel) => emit(AuthAuthenticatedAfterLogin(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          hasValidatedOtp: true)),
      (failure) =>
          emit(AuthOtpValidate(message: failure.message, userId: event.userId)),
    );
  }

  void _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthUnauthenticated());
  }
}
