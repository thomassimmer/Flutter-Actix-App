import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';
import 'package:flutteractixapp/core/widgets/app_logo.dart';
import 'package:flutteractixapp/core/widgets/custom_container.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth_login/auth_login_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth_login/auth_login_events.dart';
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
        body: Stack(children: [
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
                            if (state
                                is AuthAuthenticatedAfterRegistrationState) {
                              setState(() {
                                _isAuthenticated = true;
                              });
                            } else {
                              GlobalSnackBar.show(context, state.message);
                            }
                          }, builder: (context, state) {
                            if (state is AuthLoadingState) {
                              return _buildLoadingScreen(context, state);
                            } else {
                              return _buildSignUpScreen(context, state);
                            }
                          })),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.goNamed('home');
                            },
                            child: Text(AppLocalizations.of(context)!.comeBack),
                          ),
                        ])))),
      SuccessfulLoginAnimation(
        isVisible: _isAuthenticated,
        onAnimationComplete: () {
          GlobalSnackBar.show(context, authMessage);
          context.goNamed('recovery-codes');
        },
      ),
    ]));
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Column(children: [CircularProgressIndicator()]);
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
            context.goNamed('login');
          },
          child: Text(AppLocalizations.of(context)!.alreadyAnAccountLogin),
        ),
      ],
    );
  }
}
