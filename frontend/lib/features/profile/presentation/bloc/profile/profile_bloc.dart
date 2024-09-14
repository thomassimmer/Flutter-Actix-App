import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
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
        add(ProfileLoadRequested());
      } else if (authState is AuthUnauthenticated) {
        add(ProfileClearRequested());
      }
    });

    on<ProfileLoadRequested>(_initialize);
    on<ProfileClearRequested>(_logout);
    on<ProfileUpdateRequested>(_update);
    on<ProfileOtpGenerationRequested>(_generateTwoFactorAuthenticationConfig);
    on<ProfileOtpDisablingRequested>(_disableTwoFactorAuthentication);
    on<ProfileOtpVerificationRequested>(_verifyOneTimePassword);
    on<ProfileSetPasswordRequested>(_setPassword);
    on<ProfileUpdatePasswordRequested>(_updatePassword);
  }

  Future<void> _initialize(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
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
      ProfileClearRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileUnauthenticated());
  }

  Future<void> _update(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    final result = await postProfileUsecase.call(event.profile);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('profileUpdateSuccessfully'))));
  }

  Future<void> _generateTwoFactorAuthenticationConfig(
      ProfileOtpGenerationRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    final result = await generateOtpConfigUseCase.call();

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else {
        if (currentState is ProfileAuthenticated) {
          emit(ProfileAuthenticated(
            profile: currentState.profile,
            message: ErrorMessage(error.messageKey),
          ));
        } else {
          emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
        }
      }
    }, (generatedOtpConfig) {
      if (currentState is ProfileAuthenticated) {
        User profile = currentState.profile;
        profile.otpAuthUrl = generatedOtpConfig.otpAuthUrl;
        profile.otpBase32 = generatedOtpConfig.otpBase32;
        profile.otpVerified = false;

        emit(ProfileAuthenticated(
          profile: profile,
        ));
      }
    });
  }

  Future<void> _disableTwoFactorAuthentication(
      ProfileOtpDisablingRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    try {
      await disableOtpUseCase.call();

      if (currentState is ProfileAuthenticated) {
        User profile = currentState.profile;
        profile.otpAuthUrl = null;
        profile.otpBase32 = null;
        profile.otpVerified = false;

        emit(ProfileAuthenticated(
          profile: profile,
        ));
      }
    } on ShouldLogoutError catch (error) {
      authBloc
          .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
    } on DomainError catch (error) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    } catch (error) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(''),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage('')));
      }
    }
  }

  Future<void> _verifyOneTimePassword(
      ProfileOtpVerificationRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    try {
      await verifyOtpUseCase.call(event.code);

      if (currentState is ProfileAuthenticated) {
        User profile = currentState.profile;
        profile.otpVerified = true;

        emit(ProfileAuthenticated(
          profile: profile,
        ));
      }
    } on ShouldLogoutError catch (error) {
      authBloc
          .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
    } on DomainError catch (error) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    } catch (error) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(''),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage('')));
      }
    }
  }

  Future<void> _setPassword(
      ProfileSetPasswordRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    final result =
        await setPasswordUseCase.call(newPassword: event.newPassword);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessfully'))));
  }

  Future<void> _updatePassword(
      ProfileUpdatePasswordRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading(profile: state.profile));

    final result = await updatePasswordUseCase.call(
        currentPassword: event.currentPassword, newPassword: event.newPassword);

    result.fold((error) {
      if (error is ShouldLogoutError) {
        authBloc
            .add(AuthLogoutRequested(message: ErrorMessage(error.messageKey)));
      } else if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: ErrorMessage(error.messageKey),
        ));
      } else {
        emit(ProfileUnauthenticated(message: ErrorMessage(error.messageKey)));
      }
    },
        (profile) => emit(ProfileAuthenticated(
            profile: profile,
            message: SuccessMessage('passwordUpdateSuccessfully'))));
  }
}
