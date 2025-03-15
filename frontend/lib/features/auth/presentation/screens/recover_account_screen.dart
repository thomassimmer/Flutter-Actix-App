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

class RecoverAccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                          if (state is AuthAuthenticated) {
                            context.go('/#/profil');
                          }
                        },
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state
                                is AuthRecoveringAccountWithOtpEnabledAndUsingPassword) {
                              return _buildRecoveryCodeAndPasswordView(
                                  context, state);
                            } else if (state
                                is AuthRecoveringAccountWithOtpEnabledAndUsingOtp) {
                              return _buildRecoveryCodeAndOtpView(
                                  context, state);
                            } else if (state
                                is AuthRecoveringAccountWithOtpDisabled) {
                              return _buildRecoveryCodeView(context, state);
                            } else if (state
                                is AuthRecoveringAccountUsernameStep) {
                              return _buildUsernameStepView(context, state);
                            } else if (state is AuthLoading) {
                              return CircularProgressIndicator(
                                color: Colors.black,
                              );
                            } else {
                              return Text(state.error != null
                                  ? state.error!.display(context)
                                  : AppLocalizations.of(context)!.noContent);
                            }
                          },
                        ),
                      ))),
              SizedBox(height: 16),
              Button(
                onPressed: () {
                  context.go('/');
                },
                text: AppLocalizations.of(context)!.home,
                isPrimary: true,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStepView(
      BuildContext context, AuthRecoveringAccountUsernameStep state) {
    // Reuse the username that the user wrote on the login screen
    final TextEditingController _usernameController =
        TextEditingController(text: state.username);

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterUsername,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _usernameController,
        label: AppLocalizations.of(context)!.username,
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.next,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthDoesAccountHaveOtpEnabledRequested(
                username: _usernameController.text,
                passwordForgotten: state.passwordForgotten),
          );
        },
        isPrimary: true,
        size: ButtonSize.small,
      ),
    ]);
  }

  Widget _buildRecoveryCodeAndPasswordView(
      BuildContext context, AuthRecoveringAccountUsernameStep state) {
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _recoveryCodeController =
        TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterPassword,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _passwordController,
        label: AppLocalizations.of(context)!.password,
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterRecoveryCode,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.next,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthAccountRecoveryWithOtpEnabledAndPasswordRequested(
                username: state.username,
                password: _passwordController.text,
                recoveryCode: _recoveryCodeController.text),
          );
        },
        isPrimary: true,
        size: ButtonSize.small,
      ),
    ]);
  }

  Widget _buildRecoveryCodeView(
      BuildContext context, AuthRecoveringAccountUsernameStep state) {
    final TextEditingController _recoveryCodeController =
        TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterRecoveryCode,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.next,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthAccountRecoveryWithOtpDisabledRequested(
                username: state.username,
                recoveryCode: _recoveryCodeController.text),
          );
        },
        isPrimary: true,
        size: ButtonSize.small,
      ),
    ]);
  }

  Widget _buildRecoveryCodeAndOtpView(
      BuildContext context, AuthRecoveringAccountUsernameStep state) {
    final TextEditingController _recoveryCodeController =
        TextEditingController();
    final TextEditingController _otpController = TextEditingController();

    return Column(children: [
      Text(
        AppLocalizations.of(context)!.recoverAccount,
        style: TextStyle(color: Colors.grey, fontSize: 20),
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterRecoveryCode,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _recoveryCodeController,
        label: AppLocalizations.of(context)!.recoveryCode,
      ),
      SizedBox(height: 16),
      Text(AppLocalizations.of(context)!.enterValidationCode,
          style: TextStyle(color: Colors.grey)),
      SizedBox(height: 16),
      CustomTextField(
        controller: _otpController,
        label: AppLocalizations.of(context)!.validationCode,
      ),
      SizedBox(height: 24),
      Button(
        text: AppLocalizations.of(context)!.next,
        onPressed: () {
          BlocProvider.of<AuthBloc>(context).add(
            AuthAccountRecoveryWithOtpDisabledRequested(
                username: state.username,
                recoveryCode: _recoveryCodeController.text),
          );
        },
        isPrimary: true,
        size: ButtonSize.small,
      ),
    ]);
  }
}
