import 'package:bloc/bloc.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignupUseCase signupUseCase;
  final VerifyOTPUseCase verifyOTPUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signupUseCase,
    required this.verifyOTPUseCase,
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthOTPRequested>(_onOTPRequested);
    on<AuthOTPVerified>(_onOTPVerified);
  }

  void _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await loginUseCase.login(event.username, event.password);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) {
        if (user.otpEnabled && !user.otpVerified) {
          emit(AuthOTPRequired(userId: user.id));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      },
    );
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

    // Assuming generateOTPUseCase is a use case that triggers OTP generation.
    final result =
        await verifyOTPUseCase.generateOTP(event.userId, event.username);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (otpUrl) => emit(AuthOTPRequired(userId: event.userId)),
    );
  }

  void _onOTPVerified(AuthOTPVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await verifyOTPUseCase.verifyOTP(event.userId, event.otp);

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}
