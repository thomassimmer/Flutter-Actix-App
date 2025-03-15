import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:go_router/go_router.dart';

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
                  if (state is AuthAuthenticatedAfterLogin) {
                    context.go('/home');
                  } else if (state is AuthUnauthenticated) {
                    if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(state.error!.display(context))));
                    }
                  }
                },
                child:
                    BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
                  if (state is AuthLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.white),
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
                        Text(
                          AppLocalizations.of(context)!.welcome,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.pleaseLoginOrSignUp,
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
                          text: AppLocalizations.of(context)!.logIn,
                          isPrimary: true,
                        ),
                        SizedBox(height: 16),
                        Button(
                          onPressed: () {
                            context.go('/signup');
                          },
                          text: AppLocalizations.of(context)!.signUp,
                          isPrimary: false,
                        ),
                      ],
                    );
                  }
                }),
              ))
        ],
      ),
    );
  }
}
