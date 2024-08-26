import 'package:bloc/bloc.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/otp_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/read_authentication_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/remove_authentication_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/store_authentication_use_case.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:universal_io/io.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final OtpUseCase otpUseCase;
  final StoreAuthenticationUseCase storeAuthenticationUseCase;
  final ReadAuthenticationUseCase readAuthenticationUseCase;
  final RemoveAuthenticationUseCase removeAuthenticationUseCase;

  AuthBloc(
      {required this.loginUseCase,
      required this.signupUseCase,
      required this.otpUseCase,
      required this.storeAuthenticationUseCase,
      required this.readAuthenticationUseCase,
      required this.removeAuthenticationUseCase})
      : super(AuthLoading()) {
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
    final result = await this.readAuthenticationUseCase.readAuthentication();

    return result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (authData) => emit(AuthAuthenticatedAfterLogin(
        accessToken: authData.accessToken,
        refreshToken: authData.refreshToken,
        expiresIn: authData.expiresIn,
        hasValidatedOtp: false,
      )),
    );
  }

  void _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // We use the device locale by default on signup
    final result = await signupUseCase.signup(
        event.username, event.password, Platform.localeName);

    await result.fold(
      (userTokenEntity) async {
        // Store tokens securely after successful login
        final storeResult =
            await storeAuthenticationUseCase.storeAuthentication(
          userTokenEntity.accessToken,
          userTokenEntity.refreshToken,
          userTokenEntity.expiresIn,
        );

        storeResult.fold(
          (success) => emit(AuthAuthenticatedAfterRegistration(
              accessToken: userTokenEntity.accessToken,
              refreshToken: userTokenEntity.refreshToken,
              expiresIn: userTokenEntity.expiresIn,
              recoveryCodes: userTokenEntity.recoveryCodes,
              hasVerifiedOtp: false)),
          (failure) =>
              emit(AuthFailure(message: 'Failed to store tokens securely.')),
        );
      },
      (failure) {
        emit(AuthFailure(message: failure.message));
      },
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

    final loginResult =
        await loginUseCase.login(event.username, event.password);

    await loginResult.fold(
      (userOrUserId) async {
        await userOrUserId.fold(
          (userTokenEntity) async {
            // Store tokens securely after successful login
            final storeResult =
                await storeAuthenticationUseCase.storeAuthentication(
              userTokenEntity.accessToken,
              userTokenEntity.refreshToken,
              userTokenEntity.expiresIn,
            );

            storeResult.fold(
              (success) => emit(AuthAuthenticatedAfterLogin(
                accessToken: userTokenEntity.accessToken,
                refreshToken: userTokenEntity.refreshToken,
                expiresIn: userTokenEntity.expiresIn,
                hasValidatedOtp: false,
              )),
              (failure) => emit(
                  AuthFailure(message: 'Failed to store tokens securely.')),
            );
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
    await removeAuthenticationUseCase.removeAuthentication();

    emit(AuthUnauthenticated());
  }
}
