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
    on<AuthOTPRequested>(_onOTPRequested);
    on<AuthOTPVerified>(_onOTPVerified);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase.login(event.username, event.password);

    result.fold((failure) => emit(AuthFailure(message: failure.message)),
        (userOrUserId) {
      userOrUserId.fold((userId) => emit(AuthOTPRequired(userId: userId)),
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

  void _onOTPRequested(AuthOTPRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.generateOTP(event.userId, event.username);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (otp) => emit(AuthOTPRequired(userId: event.userId, otp: otp)),
    );
  }

  void _onOTPVerified(AuthOTPVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await otpUseCase.verifyOTP(event.userId, event.otp);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}
