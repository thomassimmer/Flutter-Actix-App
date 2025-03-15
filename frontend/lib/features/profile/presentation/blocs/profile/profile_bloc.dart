import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/disable_two_factor_authentication_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_two_factor_authentication_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_one_time_password_use_case.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/set_password_use_case.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/update_password_use_case.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
import 'package:get_it/get_it.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc authBloc;
  late StreamSubscription authBlocSubscription;
  final GetProfileUsecase getProfileUsecase =
      GetIt.instance<GetProfileUsecase>();
  final PostProfileUsecase postProfileUsecase =
      GetIt.instance<PostProfileUsecase>();
  final GenerateTwoFactorAuthenticationConfigUseCase
      generateTwoFactorAuthenticationConfigUseCase =
      GetIt.instance<GenerateTwoFactorAuthenticationConfigUseCase>();
  final DisableTwoFactorAuthenticationUseCase
      disableTwoFactorAuthenticationUseCase =
      GetIt.instance<DisableTwoFactorAuthenticationUseCase>();
  final VerifyOneTimePasswordUseCase verifyOneTimePasswordUseCase =
      GetIt.instance<VerifyOneTimePasswordUseCase>();
  final SetPasswordUseCase setPasswordUseCase =
      GetIt.instance<SetPasswordUseCase>();
  final UpdatePasswordUseCase updatePasswordUseCase =
      GetIt.instance<UpdatePasswordUseCase>();

  ProfileBloc({required this.authBloc}) : super(ProfileLoading()) {
    authBlocSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticatedState) {
        add(ProfileInitializeEvent());
      } else if (authState is AuthUnauthenticatedState) {
        add(ProfileLogoutEvent());
      }
    });

    on<ProfileInitializeEvent>(_initialize);
    on<ProfileLogoutEvent>(_logout);
    on<ProfileUpdateThemeEvent>(_updateTheme);
    on<ProfileUpdateLocaleEvent>(_updateLocale);
    on<ProfileGenerateTwoFactorAuthenticationConfigEvent>(
        _generateTwoFactorAuthenticationConfig);
    on<ProfileDisableTwoFactorAuthenticationEvent>(
        _disableTwoFactorAuthentication);
    on<ProfileVerifyOneTimePasswordEvent>(_verifyOneTimePassword);
    on<ProfileSetPasswordEvent>(_setPassword);
    on<ProfileUpdatePasswordEvent>(_updatePassword);
  }

  Future<void> _initialize(
      ProfileInitializeEvent event, Emitter<ProfileState> emit) async {
    final result = await getProfileUsecase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    }, (profile) => emit(ProfileAuthenticated(profile: profile)));
  }

  Future<void> _logout(
      ProfileLogoutEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileUnauthenticated());
  }

  Future<void> _updateTheme(
      ProfileUpdateThemeEvent event, Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    Profile profile = currentState.profile;
    profile.theme = event.theme;

    final result = await postProfileUsecase.call(profile);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('profileUpdateSuccessful'))));
  }

  Future<void> _updateLocale(
      ProfileUpdateLocaleEvent event, Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    Profile profile = currentState.profile;
    profile.locale = event.locale;

    final result = await postProfileUsecase.call(profile);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('profileUpdateSuccessful'))));
  }

  Future<void> _generateTwoFactorAuthenticationConfig(
      ProfileGenerateTwoFactorAuthenticationConfigEvent event,
      Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    final result = await generateTwoFactorAuthenticationConfigUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    }, (twoFactorAuthenticationConfig) {
      Profile profile = currentState.profile;
      profile.otpAuthUrl = twoFactorAuthenticationConfig.otpAuthUrl;
      profile.otpBase32 = twoFactorAuthenticationConfig.otpBase32;
      profile.otpVerified = false;

      emit(ProfileAuthenticated(
        profile: profile,
      ));
    });
  }

  Future<void> _disableTwoFactorAuthentication(
      ProfileDisableTwoFactorAuthenticationEvent event,
      Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    final result = await disableTwoFactorAuthenticationUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    }, (_) {
      Profile profile = currentState.profile;
      profile.otpAuthUrl = null;
      profile.otpBase32 = null;
      profile.otpVerified = false;

      emit(ProfileAuthenticated(
        profile: profile,
      ));
    });
  }

  Future<void> _verifyOneTimePassword(ProfileVerifyOneTimePasswordEvent event,
      Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    final result = await verifyOneTimePasswordUseCase.call(event.code);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    }, (_) {
      Profile profile = currentState.profile;
      profile.otpVerified = true;

      emit(ProfileAuthenticated(
          profile: profile, message: SuccessMessage("validationCodeCorrect")));
    });
  }

  Future<void> _setPassword(
      ProfileSetPasswordEvent event, Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;
    emit(ProfileLoading(profile: state.profile));

    final result =
        await setPasswordUseCase.call(newPassword: event.newPassword);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessful'))));
  }

  Future<void> _updatePassword(
      ProfileUpdatePasswordEvent event, Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;
    emit(ProfileLoading(profile: state.profile));

    final result = await updatePasswordUseCase.call(
        currentPassword: event.currentPassword, newPassword: event.newPassword);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc.add(AuthLogoutEvent(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessful'))));
  }
}
