import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/core/presentation/root_screen.dart';
import 'package:reallystick/features/auth/data/repositories/auth_repository.dart';
import 'package:reallystick/features/auth/domain/usecases/login_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/otp_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/read_authentication_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/remove_authentication_use_case.dart';
import 'package:reallystick/features/auth/domain/usecases/signup_usecase.dart';
import 'package:reallystick/features/auth/domain/usecases/store_authentication_use_case.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/screens/login_screen.dart';
import 'package:reallystick/features/auth/presentation/screens/recovery_codes_screen.dart';
import 'package:reallystick/features/auth/presentation/screens/signup_screen.dart';
import 'package:reallystick/features/auth/presentation/screens/unauthenticated_home_screen.dart';
import 'package:reallystick/features/challenges/presentation/challenges_screen.dart';
import 'package:reallystick/features/habits/presentation/habits_screen.dart';
import 'package:reallystick/features/messages/presentation/messages_screen.dart';
import 'package:reallystick/features/profile/presentation/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initialize use cases
  final AuthRepository authRepository = AuthRepository(
    baseUrl: '${dotenv.env['API_BASE_URL']}/api',
  );

  // Create an instance of AuthBloc
  final authBloc = AuthBloc(
    loginUseCase: LoginUseCase(authRepository),
    signupUseCase: SignupUseCase(authRepository),
    otpUseCase: OtpUseCase(authRepository),
    storeAuthenticationUseCase: StoreAuthenticationUseCase(),
    readAuthenticationUseCase: ReadAuthenticationUseCase(),
    removeAuthenticationUseCase: RemoveAuthenticationUseCase(),
  );

  authBloc.add(AuthInitRequested());

  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => authBloc,
      child: MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => UnauthenticatedHomeScreen(),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;

        if (authState is AuthAuthenticated) {
          return '/home';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          return '/home';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignupScreen(),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          return '/home';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/recovery-codes',
      builder: (context, state) => RecoveryCodesScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => RootScreen(),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HabitsScreen(),
        ),
        GoRoute(
          path: '/habits',
          builder: (context, state) => HabitsScreen(),
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => ChallengesScreen(),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) => MessagesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;

        if (authState is AuthAuthenticated) {
          return null;
        } else {
          return '/';
        }
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
