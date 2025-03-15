import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(fit: StackFit.expand, children: [
      Background(),
      Column(
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
                  border: Border.all(width: 1.0, color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: BlocListener<AuthBloc, AuthState>(
                      listener: (context, state) {
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
                  }, child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                    if (state is AuthLoading) {
                      return CircularProgressIndicator(
                        color: Colors.black,
                      );
                    } else {
                      return _buildSignUpScreen(context);
                    }
                  })),
                )),
            SizedBox(height: 16),
            Button(
              onPressed: () {
                context.go('/');
              },
              text: AppLocalizations.of(context)!.comeBack,
              isPrimary: false,
            ),
          ])
    ]));
  }

  Widget _buildSignUpScreen(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final String themeData = brightness == Brightness.dark ? "dark" : "light";

    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.signUp,
          style: TextStyle(color: Colors.grey, fontSize: 20),
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _usernameController,
          label: AppLocalizations.of(context)!.username,
          obscureText: false,
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: AppLocalizations.of(context)!.password,
          obscureText: true,
        ),
        SizedBox(height: 24),
        Button(
          text: AppLocalizations.of(context)!.signUp,
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthSignupRequested(
                  username: _usernameController.text,
                  password: _passwordController.text,
                  theme: themeData),
            );
          },
          isPrimary: true,
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.go('/login');
          },
          child: Text(
            AppLocalizations.of(context)!.alreadyAnAccountLogin,
          ),
        ),
      ],
    );
  }
}
