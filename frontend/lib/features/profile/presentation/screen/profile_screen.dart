import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/widgets/icon_with_warning.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/language_selection_screen.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/password_screen.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/theme_selection_screen.dart';
import 'package:flutteractixapp/features/profile/presentation/screen/two_factor_authentication_screen%20copy.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LocaleSelectionScreen()),
                );
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.theme),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ThemeSelectionScreen()),
                );
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.twoFA),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TwoFactorAuthenticationScreen()),
                );
              },
            ),
            //here
            ListTile(
              title: Text(AppLocalizations.of(context)!.changePassword),
              trailing: (IconWithWarning(
                  iconData: Icons.chevron_right,
                  shouldBeWarning: shouldBeWarning)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PasswordScreen()),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
