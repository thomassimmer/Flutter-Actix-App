import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/core/widgets/icon_with_warning.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_states.dart';
import 'package:go_router/go_router.dart';

class RootScreen extends StatelessWidget {
  final Widget child;

  const RootScreen({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
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

    return MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(listener: (context, state) {
            GlobalSnackBar.show(context, state.message);

            if (state is AuthUnauthenticatedState) {
              context.go('/');
            }
          }),
          BlocListener<ProfileBloc, ProfileState>(listener: (context, state) {
            GlobalSnackBar.show(context, state.message);
          }),
        ],
        child:
            BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
          final shouldBeWarning =
              state is ProfileAuthenticated && state.profile.passwordIsExpired;

          return Scaffold(
              appBar: AppBar(
                title: Row(children: [
                  TextButton(
                      onPressed: () {
                        context.go('/');
                      },
                      child: Row(children: [
                        Text('Flutter',
                            style: context.typographies.headingSmall
                                .copyWith(color: context.colors.background)),
                        Text(
                          'Actix',
                          style: context.typographies.headingSmall
                              .copyWith(color: context.colors.hint),
                        ),
                      ])),
                  Spacer(),
                  ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.logout),
                    onPressed: () {
                      BlocProvider.of<AuthBloc>(context).add(AuthLogoutEvent());
                    },
                    style: context.styles.buttonSmall,
                  ),
                ]),
                backgroundColor: context.colors.primary,
              ),
              body: Row(
                children: [
                  if (isLargeScreen) ...[
                    Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.primary,
                              context.colors.secondary
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: NavigationRail(
                          backgroundColor: Colors.transparent,
                          unselectedLabelTextStyle:
                              TextStyle(color: Colors.white),
                          selectedLabelTextStyle:
                              TextStyle(color: Colors.white),
                          selectedIconTheme: IconThemeData(color: Colors.blue),
                          unselectedIconTheme:
                              IconThemeData(color: Colors.white),
                          groupAlignment: 0.0,
                          selectedIndex: _calculateSelectedIndex(context),
                          onDestinationSelected: onItemTapped,
                          labelType: NavigationRailLabelType.all,
                          destinations: <NavigationRailDestination>[
                            NavigationRailDestination(
                              icon: Icon(Icons.check_circle_outline),
                              selectedIcon: Icon(Icons.check_circle),
                              label: Text(AppLocalizations.of(context)!.habits),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.flag_outlined),
                              selectedIcon: Icon(Icons.flag),
                              label: Text(
                                  AppLocalizations.of(context)!.challenges),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.message_outlined),
                              selectedIcon: Icon(Icons.message),
                              label:
                                  Text(AppLocalizations.of(context)!.messages),
                            ),
                            NavigationRailDestination(
                              icon: IconWithWarning(
                                  iconData: Icons.person_outline,
                                  shouldBeWarning: shouldBeWarning),
                              selectedIcon: IconWithWarning(
                                iconData: Icons.person,
                                shouldBeWarning: shouldBeWarning,
                              ),
                              label:
                                  Text(AppLocalizations.of(context)!.profile),
                            ),
                          ],
                        )),
                  ],
                  Expanded(
                    child: child,
                  ),
                ],
              ),
              bottomNavigationBar: isLargeScreen
                  ? null
                  : NavigationBarTheme(
                      data: NavigationBarThemeData(
                        iconTheme:
                            WidgetStateProperty.resolveWith<IconThemeData>(
                          (Set<WidgetState> states) =>
                              states.contains(WidgetState.selected)
                                  ? const IconThemeData(color: Colors.blue)
                                  : const IconThemeData(color: Colors.white),
                        ),
                        labelTextStyle:
                            WidgetStateProperty.resolveWith<TextStyle>(
                          (Set<WidgetState> states) =>
                              const TextStyle(color: Colors.white),
                        ),
                      ),
                      child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.colors.primary,
                                context.colors.secondary
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: NavigationBar(
                            backgroundColor: Colors.transparent,
                            indicatorColor: Colors.white,
                            selectedIndex: _calculateSelectedIndex(context),
                            onDestinationSelected: onItemTapped,
                            destinations: <NavigationDestination>[
                              NavigationDestination(
                                icon: Icon(Icons.check_circle_outline),
                                selectedIcon: Icon(Icons.check_circle),
                                label: AppLocalizations.of(context)!.habits,
                              ),
                              NavigationDestination(
                                icon: Icon(Icons.flag_outlined),
                                selectedIcon: Icon(Icons.flag),
                                label: AppLocalizations.of(context)!.challenges,
                              ),
                              NavigationDestination(
                                icon: Icon(Icons.message_outlined),
                                selectedIcon: Icon(Icons.message),
                                label: AppLocalizations.of(context)!.messages,
                              ),
                              NavigationDestination(
                                icon: IconWithWarning(
                                    iconData: Icons.person_outline,
                                    shouldBeWarning: shouldBeWarning),
                                selectedIcon: IconWithWarning(
                                  iconData: Icons.person,
                                  shouldBeWarning: shouldBeWarning,
                                ),
                                label: AppLocalizations.of(context)!.profile,
                              ),
                            ],
                          )),
                    ));
        }));
  }
}
