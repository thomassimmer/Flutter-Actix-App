import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/background.dart';

class RecoveryCodesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Recovery Codes'),
        ),
        body: Stack(fit: StackFit.expand, children: [
          Background(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthAuthenticated) {
                        final recoveryCodes = state.user.recoveryCodes;

                        if (recoveryCodes == null || recoveryCodes.isEmpty) {
                          return Center(
                              child: Text(
                            'No recovery codes available.',
                            style: TextStyle(color: Colors.white),
                          ));
                        } else {
                          return ListView.builder(
                            itemCount: recoveryCodes.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  recoveryCodes[index],
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          );
                        }
                      } else if (state is AuthLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        return Center(
                            child: Text(
                          'Unable to load recovery codes.',
                          style: TextStyle(color: Colors.white),
                        ));
                      }
                    },
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: Text('Home'),
                ),
              ],
            ),
          ),
        ]));
  }
}
