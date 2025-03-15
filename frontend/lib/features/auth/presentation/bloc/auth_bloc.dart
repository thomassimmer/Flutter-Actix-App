import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/check_if_otp_enabled_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_and_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_and_password_usecase%20copy.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_recovery_code_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/signup_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/validate_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_io/io.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase = GetIt.instance<LoginUseCase>();
  final SignupUseCase signupUseCase = GetIt.instance<SignupUseCase>();
  final GenerateOtpConfigUseCase generateOtpConfigUseCase =
      GetIt.instance<GenerateOtpConfigUseCase>();
  final VerifyOtpUseCase verifyOtpUseCase = GetIt.instance<VerifyOtpUseCase>();
  final ValidateOtpUsecase validateOtpUsecase =
      GetIt.instance<ValidateOtpUsecase>();
  final CheckIfOtpEnabledUsecase checkIfOtpEnabledUsecase =
      GetIt.instance<CheckIfOtpEnabledUsecase>();
  final RecoverAccountWithRecoveryCodeAndPasswordUseCase
      recoverAccountWithRecoveryCodeAndPasswordUseCase =
      GetIt.instance<RecoverAccountWithRecoveryCodeAndPasswordUseCase>();
  final RecoverAccountWithRecoveryCodeAndOtpUseCase
      recoverAccountWithRecoveryCodeAndOtpUseCase =
      GetIt.instance<RecoverAccountWithRecoveryCodeAndOtpUseCase>();
  final RecoverAccountWithRecoveryCodeUseCase
      recoverAccountWithRecoveryCodeUseCase =
      GetIt.instance<RecoverAccountWithRecoveryCodeUseCase>();

  AuthBloc() : super(AuthLoading()) {
    on<AuthInitRequested>(_onInitializeAuth);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthOtpGenerationRequested>(_onOtpGenerationRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthOtpValidationRequested>(_onOtpValidationRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthAccountRecoveryForUsernameRequested>(
        _onAccountRecoveryForUsernameRequested);
    on<AuthDoesAccountHaveOtpEnabledRequested>(
        _onDoesAccountHaveOtpEnabledRequested);
    on<AuthAccountRecoveryWithOtpEnabledAndPasswordRequested>(
        _onAccountRecoveryWithOtpEnabledAndPasswordRequested);
    on<AuthAccountRecoveryWithOtpEnabledAndOtpRequested>(
        _onAccountRecoveryWithOtpEnabledAndOtpRequested);
    on<AuthAccountRecoveryWithOtpDisabledRequested>(
        _onAccountRecoveryWithOtpDisabledRequested);
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

    try {
      // We use the device locale by default on signup
      final userToken = await signupUseCase.call(
          event.username, event.password, Platform.localeName, event.theme);

      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );

      emit(AuthAuthenticatedAfterRegistration(
          recoveryCodes: userToken.recoveryCodes, hasVerifiedOtp: false));
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }

  void _onOtpGenerationRequested(
      AuthOtpGenerationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final generatedOtpConfig = await generateOtpConfigUseCase.call();

      emit(AuthOtpVerify(
          otpAuthUrl: generatedOtpConfig.otpAuthUrl,
          otpBase32: generatedOtpConfig.otpBase32));
    } on ShouldLogoutError catch (error) {
      add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }

  void _onOtpVerificationRequested(
      AuthOtpVerificationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      await verifyOtpUseCase.call(event.code);

      emit(AuthAuthenticatedAfterRegistration(
          hasVerifiedOtp: true,
          message: SuccessMessage("validationCodeCorrect")));
    } on ShouldLogoutError catch (error) {
      add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
    } on DomainError catch (error) {
      emit(AuthOtpVerify(
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32,
          message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthOtpVerify(
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32,
          message: ErrorMessage('')));
    }
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final userTokenOrUserId =
          await loginUseCase.call(event.username, event.password);

      await userTokenOrUserId.fold(
        (userToken) async {
          // Store tokens securely after successful login
          await TokenStorage().saveTokens(
            userToken.accessToken,
            userToken.refreshToken,
          );

          emit(AuthAuthenticatedAfterLogin(
              hasValidatedOtp: false,
              message: SuccessMessage("loginSuccessfull")));
        },
        (userId) {
          emit(AuthOtpValidate(userId: userId));
        },
      );
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }

  void _onOtpValidationRequested(
      AuthOtpValidationRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final userToken = await validateOtpUsecase.call(event.userId, event.code);

      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );

      emit(AuthAuthenticatedAfterLogin(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessfull")));
    } on DomainError catch (error) {
      emit(AuthOtpValidate(
          message: ErrorMessage(error.messageKey), userId: event.userId));
    } catch (error) {
      emit(AuthOtpValidate(message: ErrorMessage(''), userId: event.userId));
    }
  }

  void _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await TokenStorage().deleteTokens();

    if (event.message == null) {
      emit(AuthUnauthenticated(message: SuccessMessage('logoutSuccessfull')));
    } else {
      emit(AuthUnauthenticated(message: event.message));
    }
  }

  void _onAccountRecoveryForUsernameRequested(
      AuthAccountRecoveryForUsernameRequested event,
      Emitter<AuthState> emit) async {
    emit(AuthRecoveringAccountUsernameStep(
        username: event.username, passwordForgotten: event.passwordForgotten));
  }

  void _onDoesAccountHaveOtpEnabledRequested(
      AuthDoesAccountHaveOtpEnabledRequested event,
      Emitter<AuthState> emit) async {
    final currentState = state;
    emit(AuthLoading());

    try {
      final isOtpEnabled = await checkIfOtpEnabledUsecase.call(event.username);

      if (currentState is AuthRecoveringAccountUsernameStep) {
        if (isOtpEnabled) {
          if (currentState.passwordForgotten) {
            emit(AuthRecoveringAccountWithOtpEnabledAndUsingOtp(
                username: event.username,
                passwordForgotten: currentState.passwordForgotten));
          } else {
            emit(AuthRecoveringAccountWithOtpEnabledAndUsingPassword(
                username: event.username,
                passwordForgotten: currentState.passwordForgotten));
          }
        } else {
          emit(AuthRecoveringAccountWithOtpDisabled(
              username: event.username,
              passwordForgotten: currentState.passwordForgotten));
        }
      }
    } on DomainError catch (error) {
      emit(AuthRecoveringAccountUsernameStep(
          username: event.username,
          passwordForgotten: event.passwordForgotten,
          message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthRecoveringAccountUsernameStep(
          username: event.username,
          passwordForgotten: event.passwordForgotten,
          message: ErrorMessage('')));
    }
  }

  void _onAccountRecoveryWithOtpEnabledAndPasswordRequested(
      AuthAccountRecoveryWithOtpEnabledAndPasswordRequested event,
      Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final userToken =
          await recoverAccountWithRecoveryCodeAndPasswordUseCase.call(
              username: event.username,
              password: event.password,
              recoveryCode: event.recoveryCode);

      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );

      emit(AuthAuthenticatedAfterLogin(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessfull")));
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }

  void _onAccountRecoveryWithOtpEnabledAndOtpRequested(
      AuthAccountRecoveryWithOtpEnabledAndOtpRequested event,
      Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final userToken = await recoverAccountWithRecoveryCodeAndOtpUseCase.call(
          username: event.username,
          code: event.code,
          recoveryCode: event.recoveryCode);

      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );

      emit(AuthAuthenticatedAfterLogin(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessfull")));
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }

  void _onAccountRecoveryWithOtpDisabledRequested(
      AuthAccountRecoveryWithOtpDisabledRequested event,
      Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final userToken = await recoverAccountWithRecoveryCodeUseCase.call(
          username: event.username, recoveryCode: event.recoveryCode);

      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );

      emit(AuthAuthenticatedAfterLogin(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessfull")));
    } on DomainError catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthUnauthenticated(message: ErrorMessage('')));
    }
  }
}
