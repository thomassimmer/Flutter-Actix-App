import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutteractixapp/core/presentation/screens/root_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/login_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/recover_account_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/recovery_codes_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/signup_screen.dart';
import 'package:flutteractixapp/features/auth/presentation/screens/unauthenticated_home_screen.dart';
import 'package:flutteractixapp/features/challenges/presentation/challenges_screen.dart';
import 'package:flutteractixapp/features/habits/presentation/habits_screen.dart';
import 'package:flutteractixapp/features/messages/presentation/messages_screen.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/profile_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => UnauthenticatedHomeScreen(),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;

        if (authState is AuthAuthenticatedState) {
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
        if (authState is AuthAuthenticatedState) {
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
        if (authState is AuthAuthenticatedState) {
          return '/home';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/recovery-codes',
      builder: (context, state) => RecoveryCodesScreen(),
    ),
    GoRoute(
      path: '/recover-account',
      builder: (context, state) => RecoverAccountScreen(),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticatedState) {
          return '/home';
        }
        return null;
      },
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

        if (authState is AuthAuthenticatedState) {
          return null;
        } else {
          return '/';
        }
      },
    ),
  ],
);
