import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/set_password_use_case.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/update_password_use_case.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_states.dart';
import 'package:get_it/get_it.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc authBloc;
  late StreamSubscription authBlocSubscription;
  final GetProfileUsecase getProfileUsecase =
      GetIt.instance<GetProfileUsecase>();
  final PostProfileUsecase postProfileUsecase =
      GetIt.instance<PostProfileUsecase>();
  final GenerateOtpConfigUseCase generateOtpConfigUseCase =
      GetIt.instance<GenerateOtpConfigUseCase>();
  final DisableOtpUseCase disableOtpUseCase =
      GetIt.instance<DisableOtpUseCase>();
  final VerifyOtpUseCase verifyOtpUseCase = GetIt.instance<VerifyOtpUseCase>();
  final SetPasswordUseCase setPasswordUseCase =
      GetIt.instance<SetPasswordUseCase>();
  final UpdatePasswordUseCase updatePasswordUseCase =
      GetIt.instance<UpdatePasswordUseCase>();

  ProfileBloc({required this.authBloc}) : super(ProfileLoading()) {
    authBlocSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(ProfileInitializeEvent());
      } else if (authState is AuthUnauthenticated) {
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
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
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
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('profileUpdateSuccessfully'))));
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
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('profileUpdateSuccessfully'))));
  }

  Future<void> _generateTwoFactorAuthenticationConfig(
      ProfileGenerateTwoFactorAuthenticationConfigEvent event,
      Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;

    emit(ProfileLoading(profile: state.profile));

    final result = await generateOtpConfigUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    }, (generatedOtpConfig) {
      Profile profile = currentState.profile;
      profile.otpAuthUrl = generatedOtpConfig.otpAuthUrl;
      profile.otpBase32 = generatedOtpConfig.otpBase32;
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

    final result = await disableOtpUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
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

    final result = await verifyOtpUseCase.call(event.code);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
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
        profile: profile,
      ));
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
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessfully'))));
  }

  Future<void> _updatePassword(
      ProfileUpdatePasswordEvent event, Emitter<ProfileState> emit) async {
    final currentState = state as ProfileAuthenticated;
    emit(ProfileLoading(profile: state.profile));

    final result = await updatePasswordUseCase.call(
        currentPassword: event.currentPassword, newPassword: event.newPassword);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessfully'))));
  }
}
