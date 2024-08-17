import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/core/themes/app_theme.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/button.dart';

class RootScreen extends StatefulWidget {
  @override
  RootScreenState createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/habits')) {
      return 0;
    }
    if (location.startsWith('/challenges')) {
      return 1;
    }
    if (location.startsWith('/messages')) {
      return 2;
    }
    if (location.startsWith('/profile')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 800;

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          GoRouter.of(context).go('/habits');
        case 1:
          GoRouter.of(context).go('/challenges');
        case 2:
          GoRouter.of(context).go('/messages');
        case 3:
          GoRouter.of(context).go('/profile');
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                'Really',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                'Stick',
                style: TextStyle(color: Colors.grey),
              ),
              Spacer(),
              BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthUnauthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Successfully logged out')),
                    );
                    context.go('/');
                  }
                },
                child: Button(
                  text: 'Logout',
                  onPressed: () {
                    BlocProvider.of<AuthBloc>(context)
                        .add(AuthLogoutRequested());
                  },
                  isPrimary: true,
                  size: ButtonSize.small,
                ),
              )
            ],
          ),
          backgroundColor: AppTheme.lightTheme.primaryColor,
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.green,
          ),
        ),
        body: Row(
          children: [
            if (isLargeScreen) ...[
              NavigationRail(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                unselectedLabelTextStyle: TextStyle(color: Colors.white),
                selectedLabelTextStyle: TextStyle(color: Colors.blue),
                selectedIconTheme: IconThemeData(color: Colors.blue),
                unselectedIconTheme: IconThemeData(color: Colors.white),
                groupAlignment: 0.0,
                selectedIndex: _calculateSelectedIndex(context),
                onDestinationSelected: onItemTapped,
                labelType: NavigationRailLabelType.all,
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.check_circle_outline),
                    selectedIcon: Icon(Icons.check_circle),
                    label: Text('Habits'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.flag_outlined),
                    selectedIcon: Icon(Icons.flag),
                    label: Text('Challenges'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.message_outlined),
                    selectedIcon: Icon(Icons.message),
                    label: Text('Messages'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ],
          ],
        ),
        bottomNavigationBar: isLargeScreen
            ? null
            : NavigationBarTheme(
                data: NavigationBarThemeData(
                  iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
                    (Set<WidgetState> states) =>
                        states.contains(WidgetState.selected)
                            ? const IconThemeData(color: Colors.blue)
                            : const IconThemeData(color: Colors.white),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                    (Set<WidgetState> states) =>
                        states.contains(WidgetState.selected)
                            ? const TextStyle(color: Colors.blue)
                            : const TextStyle(color: Colors.white),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  indicatorColor: Colors.white,
                  selectedIndex: _calculateSelectedIndex(context),
                  onDestinationSelected: onItemTapped,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.check_circle_outline),
                      selectedIcon: Icon(Icons.check_circle),
                      label: 'Habits',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.flag_outlined),
                      selectedIcon: Icon(Icons.flag),
                      label: 'Challenges',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.message_outlined),
                      selectedIcon: Icon(Icons.message),
                      label: 'Messages',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ));
  }
}
