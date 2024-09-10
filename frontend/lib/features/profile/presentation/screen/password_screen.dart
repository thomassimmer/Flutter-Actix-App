import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/mapper.dart';
import 'package:flutteractixapp/features/auth/presentation/cubit/login_cubit.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';

class PasswordScreen extends StatelessWidget {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.changePassword),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
            final errorMapper = ErrorMapper(context);

            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(errorMapper.mapFailureToMessage(state.error!))),
              );
            }
          }, child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileAuthenticated) {
                if (state.profile.passwordIsExpired) {
                  return _buildSetPasswordView(context, state);
                } else {
                  return _buildUpdatePasswordView(context, state);
                }
              } else if (state is ProfileLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(
                    child: Text(
                        AppLocalizations.of(context)!.failedToLoadProfile));
              }
            },
          ))),
    );
  }

  Widget _buildSetPasswordView(
      BuildContext context, ProfileAuthenticated state) {
    final displayPasswordError = context.select(
      (LoginCubit cubit) => cubit.state.password.displayError,
    );
    final displayPasswordErrorMessage = displayPasswordError is Exception
        ? ErrorMapper(context).mapFailureToMessage(displayPasswordError)
        : null;

    return SingleChildScrollView(
        child: Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.setNewPassword,
                  ),
                  SizedBox(height: 16),
                  Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(width: 1.0, color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(children: [
                            CustomTextField(
                              controller: _newPasswordController,
                              onChanged: (password) => context
                                  .read<LoginCubit>()
                                  .passwordChanged(password),
                              obscureText: true,
                              label: AppLocalizations.of(context)!.newPassword,
                              errorText: displayPasswordErrorMessage,
                            ),
                            SizedBox(height: 24),
                            Button(
                              text: AppLocalizations.of(context)!.verify,
                              onPressed: () {
                                BlocProvider.of<ProfileBloc>(context).add(
                                  ProfileSetPasswordRequested(
                                    newPassword: _newPasswordController.text,
                                  ),
                                );
                                _newPasswordController.text = '';
                              },
                              isPrimary: true,
                              size: ButtonSize.small,
                            ),
                          ])))
                ])))
      ],
    ));
  }

  Widget _buildUpdatePasswordView(
      BuildContext context, ProfileAuthenticated state) {
    final displayPasswordError = context.select(
      (LoginCubit cubit) => cubit.state.password.displayError,
    );
    final displayPasswordErrorMessage = displayPasswordError is Exception
        ? ErrorMapper(context).mapFailureToMessage(displayPasswordError)
        : null;

    return SingleChildScrollView(
        child: Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.updatePassword,
                  ),
                  SizedBox(height: 16),
                  Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(width: 1.0, color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(children: [
                            CustomTextField(
                              controller: _currentPasswordController,
                              label:
                                  AppLocalizations.of(context)!.currentPassword,
                              obscureText: true,
                            ),
                            SizedBox(height: 24),
                            CustomTextField(
                              controller: _newPasswordController,
                              onChanged: (password) => context
                                  .read<LoginCubit>()
                                  .passwordChanged(password),
                              obscureText: true,
                              label: AppLocalizations.of(context)!.newPassword,
                              errorText: displayPasswordErrorMessage,
                            ),
                            SizedBox(height: 24),
                            Button(
                              text: AppLocalizations.of(context)!.save,
                              onPressed: () {
                                BlocProvider.of<ProfileBloc>(context).add(
                                  ProfileUpdatePasswordRequested(
                                    currentPassword:
                                        _currentPasswordController.text,
                                    newPassword: _newPasswordController.text,
                                  ),
                                );
                                _currentPasswordController.text = '';
                                _newPasswordController.text = '';
                              },
                              isPrimary: true,
                              size: ButtonSize.small,
                            ),
                          ])))
                ])))
      ],
    ));
  }
}
