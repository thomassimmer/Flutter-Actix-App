import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/messages/message_mapper.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/custom_container.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/set_password/set_password_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/set_password/set_password_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/update_password/update_password_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/update_password/update_password_events.dart';

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
      body: BlocBuilder<ProfileBloc, ProfileState>(
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
                child: Text(AppLocalizations.of(context)!.failedToLoadProfile));
          }
        },
      ),
    );
  }

  Widget _buildSetPasswordView(
      BuildContext context, ProfileAuthenticated state) {
    final displayPasswordError = context.select(
      (ProfileSetPasswordFormBloc bloc) => bloc.state.password.displayError,
    );
    final displayPasswordErrorMessage = displayPasswordError is DomainError
        ? getTranslatedMessage(
            context, ErrorMessage(displayPasswordError.messageKey))
        : null;

    return SingleChildScrollView(
        child: Center(
            child: Column(children: [
      Text(
        AppLocalizations.of(context)!.setNewPassword,
      ),
      SizedBox(height: 16),
      CustomContainer(
          child: Column(children: [
        CustomTextField(
          controller: _newPasswordController,
          onChanged: (password) =>
              BlocProvider.of<ProfileSetPasswordFormBloc>(context)
                  .add(SetPasswordFormPasswordChangedEvent(password)),
          obscureText: true,
          label: AppLocalizations.of(context)!.newPassword,
          errorText: displayPasswordErrorMessage,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            BlocProvider.of<ProfileBloc>(context).add(
              ProfileSetPasswordEvent(
                newPassword: _newPasswordController.text,
              ),
            );
            _newPasswordController.text = '';
          },
          style: context.styles.buttonMedium,
          child: Text(AppLocalizations.of(context)!.verify),
        ),
      ]))
    ])));
  }

  Widget _buildUpdatePasswordView(
      BuildContext context, ProfileAuthenticated state) {
    final displayPasswordError = context.select(
      (ProfileUpdatePasswordFormBloc bloc) => bloc.state.password.displayError,
    );
    final displayPasswordErrorMessage = displayPasswordError is DomainError
        ? getTranslatedMessage(
            context, ErrorMessage(displayPasswordError.messageKey))
        : null;

    return SingleChildScrollView(
        child: Center(
            child: Column(children: [
      Text(
        AppLocalizations.of(context)!.updatePassword,
      ),
      SizedBox(height: 16),
      CustomContainer(
          child: Column(children: [
        CustomTextField(
          controller: _currentPasswordController,
          label: AppLocalizations.of(context)!.currentPassword,
          obscureText: true,
        ),
        SizedBox(height: 24),
        CustomTextField(
          controller: _newPasswordController,
          onChanged: (password) =>
              BlocProvider.of<ProfileUpdatePasswordFormBloc>(context)
                  .add(UpdatePasswordFormPasswordChangedEvent(password)),
          obscureText: true,
          label: AppLocalizations.of(context)!.newPassword,
          errorText: displayPasswordErrorMessage,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            BlocProvider.of<ProfileBloc>(context).add(
              ProfileUpdatePasswordEvent(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
              ),
            );
            _currentPasswordController.text = '';
            _newPasswordController.text = '';
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ])),
    ])));
  }
}
