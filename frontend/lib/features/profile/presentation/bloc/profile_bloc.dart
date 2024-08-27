import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:reallystick/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_events.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_states.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc authBloc;
  late StreamSubscription authBlocSubscription;
  final GetProfileUsecase getProfileUsecase;
  final PostProfileUsecase postProfileUsecase;

  ProfileBloc(
      {required this.getProfileUsecase,
      required this.authBloc,
      required this.postProfileUsecase})
      : super(ProfileLoading()) {
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
  }

  Future<void> _onInitializeProfile(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    final profile = await this.getProfileUsecase.getProfile();

    profile.fold((profile) => emit(ProfileAuthenticated(profile: profile)),
        (failure) => emit(ProfileUnauthenticated(message: failure.message)));
  }

  Future<void> _onLogoutRequested(
      ProfileClearRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileUnauthenticated());
  }

  Future<void> _onProfileUpdateRequest(
      ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final profile = await this.postProfileUsecase.postProfile(event.profile);

    profile.fold((profile) => emit(ProfileAuthenticated(profile: profile)),
        (failure) => emit(ProfileUnauthenticated(message: failure.message)));
  }
}
