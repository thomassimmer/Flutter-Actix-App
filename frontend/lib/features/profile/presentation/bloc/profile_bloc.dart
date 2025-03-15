import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/disable_otp_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/generate_otp_config_use_case.dart';
import 'package:flutteractixapp/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';
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

  ProfileBloc({required this.authBloc}) : super(ProfileLoading()) {
    authBlocSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(ProfileLoadRequested());
      } else if (authState is AuthUnauthenticated) {
        add(ProfileClearRequested());
      }
    });

    on<ProfileLoadRequested>(_onInitializeProfile);
    on<ProfileClearRequested>(_onLogoutRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequest);
    on<ProfileOtpGenerationRequested>(_onOtpGenerationRequested);
    on<ProfileOtpDisablingRequested>(_onOtpDisablingRequested);
    on<ProfileOtpVerificationRequested>(_onOtpVerificationRequested);
  }

  Future<void> _onInitializeProfile(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    try {
      final profile = await getProfileUsecase.call();
      emit(ProfileAuthenticated(profile: profile));
    } catch (e) {
      emit(ProfileUnauthenticated(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
      ProfileClearRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileUnauthenticated());
  }

  Future<void> _onProfileUpdateRequest(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading());

    try {
      final profile = await postProfileUsecase.call(event.profile);

      emit(ProfileAuthenticated(profile: profile));
    } catch (e) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: e.toString(),
        ));
      } else {
        emit(ProfileUnauthenticated(message: e.toString()));
      }
    }
  }

  Future<void> _onOtpGenerationRequested(
      ProfileOtpGenerationRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading());

    try {
      final generatedOtpConfig = await generateOtpConfigUseCase.call();

      if (currentState is ProfileAuthenticated) {
        User profile = currentState.profile;
        profile.otpAuthUrl = generatedOtpConfig.otpAuthUrl;
        profile.otpBase32 = generatedOtpConfig.otpBase32;
        profile.otpVerified = false;

        emit(ProfileAuthenticated(
          profile: profile,
        ));
      }
    } catch (e) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: e.toString(),
        ));
      } else {
        emit(ProfileUnauthenticated(message: e.toString()));
      }
    }
  }

  Future<void> _onOtpDisablingRequested(
      ProfileOtpDisablingRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading());

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
    } catch (e) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: e.toString(),
        ));
      } else {
        emit(ProfileUnauthenticated(message: e.toString()));
      }
    }
  }

  Future<void> _onOtpVerificationRequested(
      ProfileOtpVerificationRequested event, Emitter<ProfileState> emit) async {
    final currentState = state;
    emit(ProfileLoading());

    try {
      await verifyOtpUseCase.call(event.code);

      if (currentState is ProfileAuthenticated) {
        User profile = currentState.profile;
        profile.otpVerified = true;

        emit(ProfileAuthenticated(
          profile: profile,
        ));
      }
    } catch (e) {
      if (currentState is ProfileAuthenticated) {
        emit(ProfileAuthenticated(
          profile: currentState.profile,
          message: e.toString(),
        ));
      } else {
        emit(ProfileUnauthenticated(message: e.toString()));
      }
    }
  }
}
