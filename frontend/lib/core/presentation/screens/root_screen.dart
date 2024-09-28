import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/core/widgets/icon_with_warning.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
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
          context.goNamed('habits');
        case 1:
          context.goNamed('challenges');
        case 2:
          context.goNamed('messages');
        case 3:
          context.goNamed('profile');
      }
    }

    return MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(listener: (context, state) {
            GlobalSnackBar.show(context, state.message);

            if (state is AuthUnauthenticatedState) {
              context.goNamed('home');
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
                        context.goNamed('home');
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
                          indicatorColor: context.colors.background,
                          useIndicator: true,
                          unselectedLabelTextStyle: TextStyle(
                            color: context.colors.textOnPrimary,
                          ),
                          selectedLabelTextStyle: TextStyle(
                            color: context.colors.textOnPrimary,
                          ),
                          selectedIconTheme:
                              IconThemeData(color: context.colors.primary),
                          unselectedIconTheme: IconThemeData(
                              color: context.colors.textOnPrimary),
                          selectedIndex: _calculateSelectedIndex(context),
                          onDestinationSelected: onItemTapped,
                          labelType: NavigationRailLabelType.all,
                          destinations: <NavigationRailDestination>[
                            NavigationRailDestination(
                              icon: Icon(Icons.check_circle_outline),
                              selectedIcon: Icon(
                                Icons.check_circle,
                              ),
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
                                  ? IconThemeData(color: context.colors.primary)
                                  : IconThemeData(
                                      color: context.colors.textOnPrimary),
                        ),
                        labelTextStyle:
                            WidgetStateProperty.resolveWith<TextStyle>(
                          (Set<WidgetState> states) =>
                              TextStyle(color: context.colors.textOnPrimary),
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
                            indicatorColor: context.colors.background,
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
