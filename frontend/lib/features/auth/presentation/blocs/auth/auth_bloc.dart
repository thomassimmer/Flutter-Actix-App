import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/check_if_account_has_two_factor_authentication_enabled_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_two_factor_authentication_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_two_factor_authentication_and_one_time_password_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_with_two_factor_authentication_and_password_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/recover_account_without_two_factor_authentication_enabled_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/signup_usecase.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/validate_one_time_password_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_one_time_password_use_case.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_io/io.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase = GetIt.instance<LoginUseCase>();
  final SignupUseCase signupUseCase = GetIt.instance<SignupUseCase>();
  final GenerateTwoFactorAuthenticationConfigUseCase
      generateTwoFactorAuthenticationConfigUseCase =
      GetIt.instance<GenerateTwoFactorAuthenticationConfigUseCase>();
  final VerifyOneTimePasswordUseCase verifyOneTimePasswordUseCase =
      GetIt.instance<VerifyOneTimePasswordUseCase>();
  final ValidateOneTimePasswordUseCase validateOneTimePasswordUseCase =
      GetIt.instance<ValidateOneTimePasswordUseCase>();
  final CheckIfAccountHasTwoFactorAuthenticationEnabledUseCase
      checkIfAccountHasTwoFactorAuthenticationEnabledUseCase =
      GetIt.instance<CheckIfAccountHasTwoFactorAuthenticationEnabledUseCase>();
  final RecoverAccountWithTwoFactorAuthenticationAndPasswordUseCase
      recoverAccountWithTwoFactorAuthenticationAndPasswordUseCase =
      GetIt.instance<
          RecoverAccountWithTwoFactorAuthenticationAndPasswordUseCase>();
  final RecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordUseCase
      recoverAccountWithTwoFactorAuthenticationAndOneTimePasswordUseCase =
      GetIt.instance<
          RecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordUseCase>();
  final RecoverAccountWithoutTwoFactorAuthenticationEnabledUseCase
      recoverAccountWithoutTwoFactorAuthenticationEnabledUseCase = GetIt.instance<
          RecoverAccountWithoutTwoFactorAuthenticationEnabledUseCase>();

  AuthBloc() : super(AuthLoadingState()) {
    on<AuthInitializeEvent>(_initialize);
    on<AuthSignupEvent>(_signup);
    on<AuthGenerateTwoFactorAuthenticationConfigEvent>(
        _generateTwoFactorAuthenticationConfig);
    on<AuthVerifyOneTimePasswordEvent>(_verifyOneTimePassword);
    on<AuthLoginEvent>(_login);
    on<AuthValidateOneTimePasswordEvent>(_validateOneTimePassword);
    on<AuthLogoutEvent>(_logout);
    on<AuthRecoverAccountForUsernameEvent>(_recoverAccountForUsername);
    on<AuthCheckIfAccountHasTwoFactorAuthenticationEnabledEvent>(
        _checkIfAccountHasTwoFactorAuthenticationEnabled);
    on<AuthRecoverAccountWithTwoFactorAuthenticationAndPasswordEvent>(
        _recoverAccountWithTwoFactorAuthenticationAndPassword);
    on<AuthRecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordEvent>(
        _recoverAccountWithTwoFactorAuthenticationAndOneTimePassword);
    on<AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent>(
        _recoverAccountWithoutTwoFactorAuthenticationEnabled);
  }

  // Function to check initial authentication state
  Future<void> _initialize(
      AuthInitializeEvent event, Emitter<AuthState> emit) async {
    final result = await TokenStorage().getAccessToken();

    if (result == null) {
      emit(AuthUnauthenticatedState());
    } else {
      emit(AuthAuthenticatedAfterLoginState(
        hasValidatedOtp: false,
      ));
    }
  }

  void _signup(AuthSignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    // We use the device locale by default on signup
    final result = await signupUseCase.call(
        event.username, event.password, Platform.localeName, event.theme);

    result.fold(
        (error) => emit(
            AuthUnauthenticatedState(message: ErrorMessage(error.messageKey))),
        (userToken) async {
      emit(AuthAuthenticatedAfterRegistrationState(
          recoveryCodes: userToken.recoveryCodes, hasVerifiedOtp: false));
    });
  }

  void _generateTwoFactorAuthenticationConfig(
      AuthGenerateTwoFactorAuthenticationConfigEvent event,
      Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result = await generateTwoFactorAuthenticationConfigUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(AuthUnauthenticatedState(message: ErrorMessage(error.messageKey)));
      }
    },
        (twoFactorAuthenticationConfig) => {
              emit(AuthVerifyOneTimePasswordState(
                  otpAuthUrl: twoFactorAuthenticationConfig.otpAuthUrl,
                  otpBase32: twoFactorAuthenticationConfig.otpBase32))
            });
  }

  void _verifyOneTimePassword(
      AuthVerifyOneTimePasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    try {
      await verifyOneTimePasswordUseCase.call(event.code);

      emit(AuthAuthenticatedAfterRegistrationState(
          hasVerifiedOtp: true,
          message: SuccessMessage("validationCodeCorrect")));
    } on ShouldLogoutError catch (error) {
      add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
    } on DomainError catch (error) {
      emit(AuthVerifyOneTimePasswordState(
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32,
          message: ErrorMessage(error.messageKey)));
    } catch (error) {
      emit(AuthVerifyOneTimePasswordState(
          otpAuthUrl: event.otpAuthUrl,
          otpBase32: event.otpBase32,
          message: ErrorMessage('')));
    }
  }

  Future<void> _login(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result = await loginUseCase.call(event.username, event.password);

    result.fold(
        (error) => emit(
            AuthUnauthenticatedState(message: ErrorMessage(error.messageKey))),
        (userTokenOrUserId) {
      userTokenOrUserId.fold((userToken) {
        emit(AuthAuthenticatedAfterLoginState(
            hasValidatedOtp: false,
            message: SuccessMessage("loginSuccessful")));
      }, (userId) => emit(AuthValidateOneTimePasswordState(userId: userId)));
    });
  }

  void _validateOneTimePassword(
      AuthValidateOneTimePasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result =
        await validateOneTimePasswordUseCase.call(event.userId, event.code);

    result.fold(
        (error) => emit(AuthValidateOneTimePasswordState(
            message: ErrorMessage(error.messageKey),
            userId: event.userId)), (userToken) async {
      emit(AuthAuthenticatedAfterLoginState(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessful")));
    });
  }

  void _logout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    await TokenStorage().deleteTokens();

    if (event.message == null) {
      emit(AuthUnauthenticatedState(
          message: SuccessMessage('logoutSuccessful')));
    } else {
      emit(AuthUnauthenticatedState(message: event.message));
    }
  }

  void _recoverAccountForUsername(
      AuthRecoverAccountForUsernameEvent event, Emitter<AuthState> emit) async {
    emit(AuthRecoverAccountUsernameStepState(
        username: event.username, passwordForgotten: event.passwordForgotten));
  }

  void _checkIfAccountHasTwoFactorAuthenticationEnabled(
      AuthCheckIfAccountHasTwoFactorAuthenticationEnabledEvent event,
      Emitter<AuthState> emit) async {
    final currentState = state;
    emit(AuthLoadingState());

    final result = await checkIfAccountHasTwoFactorAuthenticationEnabledUseCase
        .call(event.username);

    result.fold(
        (error) => emit(AuthRecoverAccountUsernameStepState(
            username: event.username,
            passwordForgotten: event.passwordForgotten,
            message: ErrorMessage(error.messageKey))), (isTwoFactorAuthenticationEnabled) async {
      if (currentState is AuthRecoverAccountUsernameStepState) {
        if (isTwoFactorAuthenticationEnabled) {
          if (currentState.passwordForgotten) {
            emit(
                AuthRecoverAccountWithTwoFactorAuthenticationEnabledAndOneTimePasswordState(
                    username: event.username,
                    passwordForgotten: currentState.passwordForgotten));
          } else {
            emit(
                AuthRecoverAccountWithTwoFactorAuthenticationEnabledAndPasswordState(
                    username: event.username,
                    passwordForgotten: currentState.passwordForgotten));
          }
        } else {
          emit(AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledState(
              username: event.username,
              passwordForgotten: currentState.passwordForgotten));
        }
      }
    });
  }

  void _recoverAccountWithTwoFactorAuthenticationAndPassword(
      AuthRecoverAccountWithTwoFactorAuthenticationAndPasswordEvent event,
      Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result =
        await recoverAccountWithTwoFactorAuthenticationAndPasswordUseCase.call(
            username: event.username,
            password: event.password,
            recoveryCode: event.recoveryCode);

    result.fold(
        (error) => emit(
            AuthUnauthenticatedState(message: ErrorMessage(error.messageKey))),
        (userToken) async {
      emit(AuthAuthenticatedAfterLoginState(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessful")));
    });
  }

  void _recoverAccountWithTwoFactorAuthenticationAndOneTimePassword(
      AuthRecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordEvent
          event,
      Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result =
        await recoverAccountWithTwoFactorAuthenticationAndOneTimePasswordUseCase
            .call(
                username: event.username,
                code: event.code,
                recoveryCode: event.recoveryCode);

    result.fold(
        (error) => emit(
            AuthUnauthenticatedState(message: ErrorMessage(error.messageKey))),
        (userToken) async {
      emit(AuthAuthenticatedAfterLoginState(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessful")));
    });
  }

  void _recoverAccountWithoutTwoFactorAuthenticationEnabled(
      AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent event,
      Emitter<AuthState> emit) async {
    emit(AuthLoadingState());

    final result = await recoverAccountWithoutTwoFactorAuthenticationEnabledUseCase.call(
        username: event.username, recoveryCode: event.recoveryCode);

    result.fold(
        (error) => emit(
            AuthUnauthenticatedState(message: ErrorMessage(error.messageKey))),
        (userToken) async {
      emit(AuthAuthenticatedAfterLoginState(
          hasValidatedOtp: true, message: SuccessMessage("loginSuccessful")));
    });
  }
}
