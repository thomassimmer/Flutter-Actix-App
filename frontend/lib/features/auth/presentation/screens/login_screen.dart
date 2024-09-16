import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

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
                child: BlocListener<AuthBloc, AuthState>(listener:
                    (context, state) {
                  GlobalSnackBar.show(context, state.message);

                  if (state is AuthAuthenticatedState) {
                    context.go('/home');
                  }
                }, child:
                    BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
                  if (state is AuthLoadingState) {
                    return _buildLoadingScreen(context, state);
                  } else if (state is AuthValidateOneTimePasswordState) {
                    return _buildOneTimePasswordVerificationScreen(
                        context, state);
                  } else {
                    return _buildLoginViewScreen(context, state);
                  }
                })),
              ),
            ),
            SizedBox(height: 16),
            Button(
              text: AppLocalizations.of(context)!.comeBack,
              onPressed: () {
                context.go('/');
              },
              isPrimary: false,
            ),
          ]),
    ]));
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Column(children: [CircularProgressIndicator(color: Colors.black)]);
  }

  Widget _buildOneTimePasswordVerificationScreen(
      BuildContext context, AuthValidateOneTimePasswordState state) {
    return Column(children: [
      Text(
        AppLocalizations.of(context)!.logIn,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.twoFA,
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      SizedBox(height: 40),
      Text(
        AppLocalizations.of(context)!.enterOneTimePassword,
        style: TextStyle(color: Colors.white),
      ),
      SizedBox(height: 40),
      CustomTextField(
        controller: _codeController,
        label: AppLocalizations.of(context)!.validationCode,
        obscureText: true,
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.logIn,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthValidateOneTimePasswordEvent(
              userId: state.userId,
              code: _codeController.text,
            ),
          );
        },
        isPrimary: true,
      ),
    ]);
  }

  Widget _buildLoginViewScreen(BuildContext context, AuthState state) {
    return Column(children: [
      Text(
        AppLocalizations.of(context)!.logIn,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: _usernameController,
        label: AppLocalizations.of(context)!.username,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: _passwordController,
        label: AppLocalizations.of(context)!.password,
        obscureText: true,
      ),
      TextButton(
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
              AuthRecoverAccountForUsernameEvent(
                  username: _usernameController.text, passwordForgotten: true));
          context.go('/recover-account');
        },
        child: Text(
          AppLocalizations.of(context)!.passwordForgotten,
        ),
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.logIn,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthLoginEvent(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
        },
        isPrimary: true,
      ),
      TextButton(
        onPressed: () {
          context.go('/signup');
        },
        child: Text(
          AppLocalizations.of(context)!.noAccountCreateOne,
        ),
      ),
    ]);
  }
}
