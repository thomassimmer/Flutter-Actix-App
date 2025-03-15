import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';

class RecoveryCodesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recovery Codes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final recoveryCodes = state.user.recoveryCodes;

              if (recoveryCodes == null || recoveryCodes.isEmpty) {
                return Center(child: Text('No recovery codes available.'));
              } else {
                return ListView.builder(
                  itemCount: recoveryCodes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(recoveryCodes[index]),
                    );
                  },
                );
              }
            } else if (state is AuthLoading) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Center(child: Text('Unable to load recovery codes.'));
            }
          },
        ),
      ),
    );
  }
}
