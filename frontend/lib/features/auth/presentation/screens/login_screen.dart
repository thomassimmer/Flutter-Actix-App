import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_events.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:reallystick/features/auth/presentation/widgets/submit_button.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.pushNamed(context, '/otp-verification');
            } else if (state is AuthFailure) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              SubmitButton(
                text: 'Login',
                onPressed: () {
                  BlocProvider.of<AuthBloc>(context).add(
                    AuthLoginRequested(
                      username: _usernameController.text,
                      password: _passwordController.text,
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                child: Text('Come back'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/signup');
                },
                child: Text('No account? Create one'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
