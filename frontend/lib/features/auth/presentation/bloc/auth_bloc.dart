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
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthOtpRequested>(_onOTPRequested);
    on<AuthOtpFirstTimeVerified>(_onOTPFirstTimeVerified);
    on<AuthOTPVerified>(_onOTPVerified);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase.login(event.username, event.password);

    result.fold((failure) => emit(AuthFailure(message: failure.message)),
        (userOrUserId) {
      userOrUserId.fold((userId) => emit(AuthOtpRequired(userId: userId)),
          (user) => emit(AuthAuthenticated(user: user)));
    });
  }

  void _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthUnauthenticated());
  }

  void _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await signupUseCase.signup(event.username, event.password);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  void _onOTPRequested(AuthOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.generateOTP(event.user.id, event.username);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (otp) => emit(AuthOtpFirstTimeRequired(user: event.user, otp: otp)),
    );
  }

  void _onOTPFirstTimeVerified(
      AuthOtpFirstTimeVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.verifyOTP(event.user.id, event.code);

    result.fold(
      (failure) => emit(
          AuthOtpFirstTimeFailure(message: failure.message, user: event.user)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  void _onOTPVerified(AuthOTPVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.verifyOTP(event.userId, event.otp);

    result.fold(
      (failure) =>
          emit(AuthOtpFailure(message: failure.message, userId: event.userId)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}
