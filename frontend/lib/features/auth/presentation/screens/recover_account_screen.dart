import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/successful_login_animation.dart';
import 'package:go_router/go_router.dart';

class RecoverAccountScreen extends StatefulWidget {
  @override
  RecoverAccountScreenState createState() => RecoverAccountScreenState();
}

class RecoverAccountScreenState extends State<RecoverAccountScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final authMessage = context.select((AuthBloc bloc) => bloc.state.message);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                      border:
                          Border.all(width: 1.0, color: Colors.blue.shade200),
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
                          },
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state
                                  is AuthRecoverAccountWithTwoFactorAuthenticationEnabledAndPasswordState) {
                                return _buildRecoveryCodeAndPasswordView(
                                    context, state);
                              } else if (state
                                  is AuthRecoverAccountWithTwoFactorAuthenticationEnabledAndOneTimePasswordState) {
                                return _buildRecoveryCodeAndOneTimePasswordView(
                                    context, state);
                              } else if (state
                                  is AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledState) {
                                return _buildRecoveryCodeView(context, state);
                              } else if (state
                                  is AuthRecoverAccountUsernameStepState) {
                                return _buildUsernameStepView(context, state);
                              } else if (state is AuthLoadingState) {
                                return CircularProgressIndicator(
                                  color: Colors.black,
                                );
                              } else {
                                return Text(state.message != null
                                    ? getTranslatedMessage(
                                        context, state.message!)
                                    : AppLocalizations.of(context)!.noContent);
                              }
                            },
                          ),
                        ))),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.goNamed('home');
                  },
                  child: Text(AppLocalizations.of(context)!.home),
                  style: context.styles.buttonSmall,
                ),
              ],
            ),
          SuccessfulLoginAnimation(
            isVisible: _isAuthenticated,
            onAnimationComplete: () {
              GlobalSnackBar.show(context, authMessage);
              context.goNamed('password');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStepView(
      BuildContext context, AuthRecoverAccountUsernameStepState state) {
    // Reuse the username that the user wrote on the login screen
    final TextEditingController usernameController =
        TextEditingController(text: state.username);

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterUsername,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: usernameController,
        label: AppLocalizations.of(context)!.username,
      ),
      SizedBox(height: 24),
      ElevatedButton(
          child: Text(AppLocalizations.of(context)!.next),
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthCheckIfAccountHasTwoFactorAuthenticationEnabledEvent(
                  username: usernameController.text,
                  passwordForgotten: state.passwordForgotten),
            );
          },
          style: context.styles.buttonSmall),
    ]);
  }

  Widget _buildRecoveryCodeAndPasswordView(
      BuildContext context, AuthRecoverAccountUsernameStepState state) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController recoveryCodeController =
        TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterPassword,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: passwordController,
        label: AppLocalizations.of(context)!.password,
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterRecoveryCode,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 24),
      ElevatedButton(
          child: Text(AppLocalizations.of(context)!.next),
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthRecoverAccountWithTwoFactorAuthenticationAndPasswordEvent(
                  username: state.username,
                  password: passwordController.text,
                  recoveryCode: recoveryCodeController.text),
            );
          },
          style: context.styles.buttonSmall),
    ]);
  }

  Widget _buildRecoveryCodeView(
      BuildContext context, AuthRecoverAccountUsernameStepState state) {
    final TextEditingController recoveryCodeController =
        TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterRecoveryCode,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 24),
      ElevatedButton(
          child: Text(AppLocalizations.of(context)!.next),
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent(
                  username: state.username,
                  recoveryCode: recoveryCodeController.text),
            );
          },
          style: context.styles.buttonSmall),
    ]);
  }

  Widget _buildRecoveryCodeAndOneTimePasswordView(
      BuildContext context, AuthRecoverAccountUsernameStepState state) {
    final TextEditingController recoveryCodeController =
        TextEditingController();
    final TextEditingController otpController = TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterRecoveryCode,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 16),
      Text(
        AppLocalizations.of(context)!.enterValidationCode,
      ),
      SizedBox(height: 16),
      CustomTextField(
        controller: otpController,
        label: AppLocalizations.of(context)!.validationCode,
      ),
      SizedBox(height: 24),
      ElevatedButton(
          child: Text(AppLocalizations.of(context)!.next),
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent(
                  username: state.username,
                  recoveryCode: recoveryCodeController.text),
            );
          },
          style: context.styles.buttonSmall),
    ]);
  }
}
