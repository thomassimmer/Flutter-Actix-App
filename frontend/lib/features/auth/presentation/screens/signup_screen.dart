import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/background.dart';
import 'package:reallystick/features/auth/presentation/widgets/button.dart';
import 'package:reallystick/features/auth/presentation/widgets/custom_text_field.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(fit: StackFit.expand, children: [
      Background(),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<AuthBloc, AuthState>(listener: (context, state) {
          if (state is AuthAuthenticatedAfterRegistration) {
            if (state.recoveryCodes != null) {
              context.go('/recovery-codes');
            } else {
              context.go('/home');
            }
          }
          if (state is AuthFailure) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          }
        }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state is AuthLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Placeholder(),
                ),
                SizedBox(height: 40),
                Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border.all(width: 1.0, color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(children: [
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Username',
                            obscureText: false,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                          ),
                          SizedBox(height: 24),
                          Button(
                            text: 'Sign Up',
                            onPressed: () {
                              BlocProvider.of<AuthBloc>(context).add(
                                AuthSignupRequested(
                                  username: _usernameController.text,
                                  password: _passwordController.text,
                                ),
                              );
                            },
                            isPrimary: true,
                          ),
                        ]))),
                SizedBox(height: 16),
                Button(
                  onPressed: () {
                    context.go('/');
                  },
                  text: 'Come back',
                  isPrimary: false,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    'Already have an account? Sign in',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          }
        })),
      ),
    ]));
  }
}
