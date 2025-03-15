import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/background.dart';
import 'package:reallystick/features/auth/presentation/widgets/button.dart';
import 'package:reallystick/features/auth/presentation/widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Background(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<AuthBloc, AuthState>(listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/home');
              if (state.user.otpEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Your validation code was correct!')),
                );
              }
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          }, child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
            if (state is AuthLoading) {
              return Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is AuthOTPRequired) {
              return Column(
                children: [
                  SizedBox(height: 40),
                  Text(
                    'Two factor authentication',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Enter the 6-digit code generated by your app to confirm your authentication',
                    style: TextStyle(color: Colors.white),
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
                              controller: _otpController,
                              label: 'Validation code',
                              obscureText: true,
                            ),
                            SizedBox(height: 24),
                            Button(
                              text: 'Login',
                              onPressed: () {
                                BlocProvider.of<AuthBloc>(context).add(
                                  AuthOTPVerified(
                                    userId: state.userId,
                                    otp: _otpController.text,
                                  ),
                                );
                              },
                              isPrimary: true,
                            ),
                          ]))),
                  SizedBox(height: 16),
                  Button(
                    text: 'Come back',
                    onPressed: () {
                      BlocProvider.of<AuthBloc>(context)
                          .add(AuthLogoutRequested());
                      context.go('/');
                    },
                    isPrimary: false,
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _usernameController,
                                label: 'Username',
                              ),
                              SizedBox(height: 16),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                obscureText: true,
                              ),
                              SizedBox(height: 24),
                              Button(
                                text: 'Login',
                                onPressed: () {
                                  BlocProvider.of<AuthBloc>(context).add(
                                    AuthLoginRequested(
                                      username: _usernameController.text,
                                      password: _passwordController.text,
                                    ),
                                  );
                                },
                                isPrimary: true,
                              ),
                            ],
                          ))),
                  SizedBox(height: 16),
                  Button(
                    text: 'Come back',
                    onPressed: () {
                      context.go('/');
                    },
                    isPrimary: false,
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.go('/signup');
                    },
                    child: Text(
                      'No account? Create one',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            }
          })),
        ),
      ]),
    );
  }
}
