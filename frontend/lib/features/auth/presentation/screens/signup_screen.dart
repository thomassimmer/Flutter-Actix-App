import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_login/auth_login_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_login/auth_login_events.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/successful_login_animation.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final authMessage = context.select((AuthBloc bloc) => bloc.state.message);

    return Scaffold(
        body: Stack(fit: StackFit.expand, children: [
      Background(),
      if (!_isAuthenticated)
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
                    color: context.colors.background,
                    border: Border.all(width: 1.0, color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: BlocListener<AuthBloc, AuthState>(
                        listener: (context, state) {
                      if (state is AuthAuthenticatedState) {
                        setState(() {
                          _isAuthenticated = true;
                        });
                      } else {
                        GlobalSnackBar.show(context, state.message);
                      }
                    }, child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                      if (state is AuthLoadingState) {
                        return _buildLoadingScreen(context, state);
                      } else {
                        return _buildSignUpScreen(context, state);
                      }
                    })),
                  )),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                child: Text(AppLocalizations.of(context)!.comeBack),
              ),
            ]),
      SuccessfulLoginAnimation(
        isVisible: _isAuthenticated,
        onAnimationComplete: () {
          GlobalSnackBar.show(context, authMessage);
          context.go('/recovery-codes');
        },
      ),
    ]));
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Column(children: [CircularProgressIndicator(color: Colors.black)]);
  }

  Widget _buildSignUpScreen(BuildContext context, AuthState state) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final String themeData = brightness == Brightness.dark ? "dark" : "light";

    final displayUsernameError = context.select(
      (AuthSignupFormBloc authSignupFormBloc) =>
          authSignupFormBloc.state.username.displayError,
    );
    final displayUsernameErrorMessage = displayUsernameError is DomainError
        ? getTranslatedMessage(
            context, ErrorMessage(displayUsernameError.messageKey))
        : null;

    final displayPasswordError = context.select(
      (AuthSignupFormBloc authSignupFormBloc) =>
          authSignupFormBloc.state.password.displayError,
    );
    final displayPasswordErrorMessage = displayPasswordError is DomainError
        ? getTranslatedMessage(
            context, ErrorMessage(displayPasswordError.messageKey))
        : null;

    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.signUp,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _usernameController,
          onChanged: (username) => BlocProvider.of<AuthSignupFormBloc>(context)
              .add(SignupFormUsernameChangedEvent(username)),
          label: AppLocalizations.of(context)!.username,
          obscureText: false,
          errorText: displayUsernameErrorMessage,
        ),
        SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          onChanged: (password) => BlocProvider.of<AuthSignupFormBloc>(context)
              .add(SignupFormPasswordChangedEvent(password)),
          obscureText: true,
          label: AppLocalizations.of(context)!.password,
          errorText: displayPasswordErrorMessage,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.signUp),
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthSignupEvent(
                  username: _usernameController.text,
                  password: _passwordController.text,
                  theme: themeData),
            );
          },
        ),
        SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.go('/login');
          },
          child: Text(AppLocalizations.of(context)!.alreadyAnAccountLogin),
        ),
      ],
    );
  }
}
