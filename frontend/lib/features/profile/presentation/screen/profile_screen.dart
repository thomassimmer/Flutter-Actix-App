import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/widgets/icon_with_warning.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_states.dart';
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
                context.go('/profile/language'); // Navigate using GoRouter
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.theme),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.go('/profile/theme'); // Navigate using GoRouter
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.twoFA),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                context.go('/profile/two-factor-authentication'); // Go to 2FA
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.changePassword),
              trailing: IconWithWarning(
                  iconData: Icons.chevron_right,
                  shouldBeWarning: shouldBeWarning),
              onTap: () {
                context.go('/profile/password'); // Navigate to password change
              },
            ),
          ],
        ),
      );
    });
  }
}
