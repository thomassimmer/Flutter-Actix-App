import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'package:reallystick/features/profile/data/repositories/profile_repository.dart';
import 'package:reallystick/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:reallystick/features/profile/domain/usecases/post_profile_usecase.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_states.dart';
import 'package:reallystick/features/profile/presentation/screen/profile_screen.dart';
import 'package:universal_io/io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final String baseUrl = '${dotenv.env['API_BASE_URL']}/api';

  final AuthRepository authRepository = AuthRepository(baseUrl: baseUrl);
  final ProfileRepository profileRepository =
      ProfileRepository(baseUrl: baseUrl);

  final authBloc = AuthBloc(
    loginUseCase: LoginUseCase(authRepository),
    signupUseCase: SignupUseCase(authRepository),
    otpUseCase: OtpUseCase(authRepository),
    storeAuthenticationUseCase: StoreAuthenticationUseCase(),
    readAuthenticationUseCase: ReadAuthenticationUseCase(),
    removeAuthenticationUseCase: RemoveAuthenticationUseCase(),
  );

  final profileBloc = ProfileBloc(
      authBloc: authBloc,
      getProfileUsecase: GetProfileUsecase(profileRepository),
      postProfileUsecase: PostProfileUsecase(profileRepository));

  authBloc.add(AuthInitRequested());

  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => authBloc,
      child:
          BlocProvider<ProfileBloc>(create: (_) => profileBloc, child: MyApp()),
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
      builder: (context, state, child) => RootScreen(child: child),
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
    return BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
      Locale locale = Locale(Platform.localeName); // device locale by default

      if (state is ProfileAuthenticated) {
        locale = Locale(state.profile.locale);
      }

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    });
  }
}
