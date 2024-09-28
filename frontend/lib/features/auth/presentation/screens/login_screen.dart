import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/widgets/app_logo.dart';
import 'package:flutteractixapp/core/widgets/custom_container.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/successful_login_animation.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final authMessage = context.select((AuthBloc bloc) => bloc.state.message);

    return Scaffold(
      body: Stack(
        children: [
          Background(),
          if (!_isAuthenticated)
            SingleChildScrollView(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppLogo(),
                          SizedBox(height: 40),
                          CustomContainer(
                            child: BlocConsumer<AuthBloc, AuthState>(
                              listener: (context, state) {
                                if (state is AuthAuthenticatedState) {
                                  setState(() {
                                    _isAuthenticated = true;
                                  });
                                } else {
                                  GlobalSnackBar.show(context, state.message);
                                }
                              },
                              builder: (context, state) {
                                if (state is AuthLoadingState) {
                                  return _buildLoadingScreen(context, state);
                                } else if (state
                                    is AuthValidateOneTimePasswordState) {
                                  return _buildOneTimePasswordVerificationScreen(
                                      context, state);
                                } else {
                                  return _buildLoginViewScreen(context, state);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            child: Text(AppLocalizations.of(context)!.comeBack),
                            onPressed: () {
                              context.goNamed('home');
                            },
                          ),
                        ],
                      ),
                    ))),
          SuccessfulLoginAnimation(
            isVisible: _isAuthenticated,
            onAnimationComplete: () {
              GlobalSnackBar.show(context, authMessage);
              context.goNamed('home');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Column(children: [CircularProgressIndicator()]);
  }

  Widget _buildOneTimePasswordVerificationScreen(
      BuildContext context, AuthValidateOneTimePasswordState state) {
    return Column(children: [
      Text(
        AppLocalizations.of(context)!.logIn,
        style: TextStyle(fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.twoFA,
        style: TextStyle(fontSize: 18),
      ),
      SizedBox(height: 40),
      Text(
        AppLocalizations.of(context)!.enterOneTimePassword,
      ),
      SizedBox(height: 40),
      CustomTextField(
        controller: _codeController,
        label: AppLocalizations.of(context)!.validationCode,
        obscureText: true,
      ),
      SizedBox(height: 24),
      ElevatedButton(
        child: Text(AppLocalizations.of(context)!.logIn),
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthValidateOneTimePasswordEvent(
              userId: state.userId,
              code: _codeController.text,
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildLoginViewScreen(BuildContext context, AuthState state) {
    return Column(children: [
      Text(
        AppLocalizations.of(context)!.logIn,
        style: TextStyle(fontSize: 20),
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
          context.goNamed('recover-account');
        },
        child: Text(AppLocalizations.of(context)!.passwordForgotten),
      ),
      SizedBox(height: 24),
      ElevatedButton(
        child: Text(AppLocalizations.of(context)!.logIn),
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthLoginEvent(
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          );
        },
      ),
      TextButton(
        onPressed: () {
          context.goNamed('signup');
        },
        child: Text(AppLocalizations.of(context)!.noAccountCreateOne),
      ),
    ]);
  }
}
