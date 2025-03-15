import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/background.dart';
import 'package:reallystick/features/auth/presentation/widgets/button.dart';

class UnauthenticatedHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Background(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Placeholder(),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Welcome to ReallyStick',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Please login or sign up to continue',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  Button(
                    onPressed: () {
                      context.go('/login');
                    },
                    text: 'Login',
                    isPrimary: true,
                  ),
                  SizedBox(height: 16),
                  Button(
                    onPressed: () {
                      context.go('/signup');
                    },
                    text: 'Sign Up',
                    isPrimary: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
