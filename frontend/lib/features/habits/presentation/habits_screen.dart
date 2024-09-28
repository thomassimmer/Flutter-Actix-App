import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';

class HabitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
      if (state is ProfileAuthenticated) {
        final username = state.profile.username;
        return Center(
          child: Text(AppLocalizations.of(context)!.hello(username)),
        );
      } else {
        return SizedBox.shrink();
      }
    });
  }
}
