import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';
import 'package:flutteractixapp/features/profile/presentation/utils/error_mapper.dart';

class LocaleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
        ),
        body: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.error != null) {
              final errorMessage =
                  getProfileErrorMessage(context, state.error!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileAuthenticated) {
                return _buildLocaleSelectionView(context, state);
              } else if (state is ProfileLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(
                    child: Text(
                        AppLocalizations.of(context)!.failedToLoadProfile));
              }
            },
          ),
        ));
  }

  Widget _buildLocaleSelectionView(
      BuildContext context, ProfileAuthenticated state) {
    final List<Map<String, String>> locales = [
      {'code': 'en', 'name': 'English'},
      {'code': 'fr', 'name': 'Français'},
    ];

    return Column(
        children: locales.map((locale) {
      return ListTile(
        title: Text(locale['name']!),
        leading: Radio<String>(
          value: locale['code']!,
          groupValue: state.profile.locale,
          onChanged: (String? value) {
            User profile = state.profile;
            profile.locale = value!;

            BlocProvider.of<ProfileBloc>(context)
                .add(ProfileUpdateRequested(profile: profile));
          },
        ),
      );
    }).toList());
  }
}
