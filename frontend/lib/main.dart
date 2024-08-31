import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutteractixapp/core/presentation/root_screen.dart';
import 'package:flutteractixapp/core/service_locator.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/login_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/recovery_codes_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/signup_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/unauthenticated_home_screen.dart';
import 'package:flutteractixapp/features/challenges/presentation/challenges_screen.dart';
import 'package:flutteractixapp/features/habits/presentation/habits_screen.dart';
import 'package:flutteractixapp/features/messages/presentation/messages_screen.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/profile_screen.dart';
import 'package:universal_io/io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  setup();

  final authBloc = AuthBloc();
  final profileBloc = ProfileBloc(authBloc: authBloc);

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

      final Brightness brightness = MediaQuery.of(context).platformBrightness;
      ThemeData themeData =
          brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

      if (state is ProfileAuthenticated) {
        locale = Locale(state.profile.locale);
        themeData = state.profile.theme == 'dark'
            ? ThemeData.dark()
            : ThemeData.light();
      }

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        locale: locale,
        theme: themeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    });
  }
}
