import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_events.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_states.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc authBloc;
  late StreamSubscription authBlocSubscription;
  final GetProfileUsecase getProfileUsecase;

  ProfileBloc({required this.getProfileUsecase, required this.authBloc})
      : super(ProfileLoading()) {
    // Écoute les changements d'état du AuthBloc
    authBlocSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        add(ProfileLoadRequested());
      } else if (authState is AuthUnauthenticated) {
        add(ProfileClearRequested());
      }
    });

    on<ProfileLoadRequested>(_onInitializeProfile);
    on<ProfileClearRequested>(_onLogoutRequested);
  }

  Future<void> _onInitializeProfile(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    if (authBloc.state is AuthAuthenticated) {
      final accessToken = (authBloc.state as AuthAuthenticated).accessToken;
      final profile = await this.getProfileUsecase.getProfile(accessToken);

      profile.fold((profile) => emit(ProfileAuthenticated(profile: profile)),
          (failure) => emit(ProfileUnauthenticated(message: failure.message)));
    } else {
      emit(ProfileUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
      ProfileClearRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileUnauthenticated());
  }
}
