import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/core/presentation/root_screen.dart';
import 'package:reallystick/features/challenges/presentation/challenges_screen.dart';
import 'package:reallystick/features/habits/presentation/habits_screen.dart';
import 'package:reallystick/features/messages/presentation/messages_screen.dart';
import 'package:reallystick/features/profile/presentation/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(initialLocation: '/', routes: [
  ShellRoute(
    builder: (
      BuildContext context,
      GoRouterState state,
      Widget child,
    ) =>
        RootScreen(),
    routes: [
      GoRoute(
        path: '/',
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
  )
]);

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
