import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';

class ThemeSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectTheme),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileAuthenticated) {
            return _buildThemeSelectionView(context, state);
          } else if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(child: Text('Failed to load profile'));
          }
        },
      ),
    );
  }

  Widget _buildThemeSelectionView(
      BuildContext context, ProfileAuthenticated state) {
    final List<Map<String, String>> themes = [
      {'code': 'light', 'name': AppLocalizations.of(context)!.light},
      {'code': 'dark', 'name': AppLocalizations.of(context)!.dark},
    ];

    return Column(
        children: themes.map((theme) {
      return ListTile(
        title: Text(theme['name']!),
        leading: Radio<String>(
          value: theme['code']!,
          groupValue: state.profile.theme,
          onChanged: (String? value) {
            final profile = User(
              username: state.profile.username,
              locale: state.profile.locale,
              theme: value!,
            );
            BlocProvider.of<ProfileBloc>(context)
                .add(ProfileUpdateRequested(profile: profile));
          },
        ),
      );
    }).toList());
  }
}
