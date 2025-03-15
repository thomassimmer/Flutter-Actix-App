import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/app_logo.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:go_router/go_router.dart';

class UnauthenticatedHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          GlobalSnackBar.show(context, state.message);

          if (state is AuthAuthenticatedState) {
            context.goNamed('home');
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              Background(),
              SingleChildScrollView(
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                          if (state is AuthLoadingState) {
                            return _buildLoadingScreen(context, state);
                          } else {
                            return _buildUnauthenticatedHomeScreen(
                                context, state);
                          }
                        }),
                      )))
            ],
          ),
        ));
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildUnauthenticatedHomeScreen(
      BuildContext context, AuthState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogo(),
        SizedBox(height: 40),
        Text(
          AppLocalizations.of(context)!.welcome,
          textAlign: TextAlign.center,
          style: context.typographies.headingLarge
              .copyWith(color: context.colors.textOnPrimary),
        ),
        SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.pleaseLoginOrSignUp,
          style: TextStyle(
            fontSize: 18,
            color: context.colors.hint,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            context.goNamed('login');
          },
          child: Text(AppLocalizations.of(context)!.logIn),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            context.goNamed('signup');
          },
          style: ButtonStyle(
              backgroundColor:
                  WidgetStatePropertyAll(context.colors.secondary)),
          child: Text(AppLocalizations.of(context)!.signUp),
        ),
      ],
    );
  }
}
