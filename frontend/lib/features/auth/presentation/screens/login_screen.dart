import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/utils/error_mapper.dart';
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
                  if (state is AuthAuthenticated) {
                    context.go('/home');
                  } else if (state is AuthOtpValidate) {
                    if (state.error != null) {
                      final errorMessage =
                          getProfileErrorMessage(context, state.error!);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(errorMessage)));
                    }
                  } else if (state is AuthUnauthenticated) {
                    if (state.error != null) {
                      final errorMessage =
                          getProfileErrorMessage(context, state.error!);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(errorMessage)));
                    }
                  }
                }, child:
                    BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
                  if (state is AuthLoading) {
                    return CircularProgressIndicator(color: Colors.black);
                  } else if (state is AuthOtpValidate) {
                    return _buildOtpVerificationScreen(context, state);
                  } else {
                    return _buildLoginViewScreen(context);
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

  Widget _buildOtpVerificationScreen(
      BuildContext context, AuthOtpValidate state) {
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
        AppLocalizations.of(context)!.enterOtp,
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
            AuthOtpValidationRequested(
              userId: state.userId,
              code: _codeController.text,
            ),
          );
        },
        isPrimary: true,
      ),
    ]);
  }

  Widget _buildLoginViewScreen(BuildContext context) {
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
              AuthAccountRecoveryForUsernameRequested(
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
            AuthLoginRequested(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
        },
        isPrimary: true,
      ),
      // SizedBox(height: 16),
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
