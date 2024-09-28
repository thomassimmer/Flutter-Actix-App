import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/icon_with_warning.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
      var shouldBeWarning =
          state is ProfileAuthenticated && state.profile.passwordIsExpired;

      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.profileSettings),
        ),
        body: ListView(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.language),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.goNamed('language'); // Navigate using GoRouter
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.theme),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.goNamed('theme'); // Navigate using GoRouter
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.twoFA),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.goNamed('two-factor-authentication'); // Go to 2FA
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.changePassword),
              trailing: IconWithWarning(
                  iconData: Icons.chevron_right,
                  shouldBeWarning: shouldBeWarning),
              onTap: () {
                context.goNamed('password'); // Navigate to password change
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.about),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.goNamed('about'); // Navigate to password change
              },
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton(
                onPressed: () {
                  BlocProvider.of<AuthBloc>(context).add(AuthLogoutEvent());
                },
                style: context.styles.buttonMedium,
                child: Text(AppLocalizations.of(context)!.logout),
              ),
            )
          ],
        ),
      );
    });
  }
}
