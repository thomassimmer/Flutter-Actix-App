import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:reallystick/features/profile/presentation/bloc/profile_states.dart';

class HabitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(builder: (context, state) {
      
      if (state is ProfileAuthenticated) {
        final username = state.profile.username;
        return Center(
          child: Text('Welcome $username'),
        );
      } else {
        return Center(
          child: Text('Habits Screen'),
        );
      }
    });
  }
}
