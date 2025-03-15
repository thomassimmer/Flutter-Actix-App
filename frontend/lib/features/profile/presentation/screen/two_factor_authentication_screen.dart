import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile/profile_states.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorAuthenticationScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.twoFA),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileAuthenticated) {
                if (state.profile.otpVerified) {
                  return _buildTwoFactorAuthenticationRegenerateConfigOrDisableView(
                      context, state);
                } else if (state.profile.otpAuthUrl != null) {
                  return _buildOneTimePasswordVerificationView(context, state);
                } else {
                  return _buildTwoFactorAuthenticationSetupView(context, state);
                }
              } else if (state is ProfileLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(
                    child: Text(
                        AppLocalizations.of(context)!.failedToLoadProfile));
              }
            },
          )),
    );
  }

  Widget _buildTwoFactorAuthenticationRegenerateConfigOrDisableView(
      BuildContext context, ProfileAuthenticated state) {
    return Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.twoFAIsWellSetup,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          child: Text(
                              AppLocalizations.of(context)!.generateNewQrCode),
                          onPressed: () {
                            BlocProvider.of<ProfileBloc>(context).add(
                              ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                            );
                          },
                          style: context.styles.buttonSmall),
                      SizedBox(width: 16),
                      ElevatedButton(
                          child:
                              Text(AppLocalizations.of(context)!.disableTwoFA),
                          onPressed: () {
                            BlocProvider.of<ProfileBloc>(context).add(
                              ProfileDisableTwoFactorAuthenticationEvent(),
                            );
                          },
                          style: context.styles.buttonSmall),
                    ],
                  )
                ])))
      ],
    );
  }

  Widget _buildOneTimePasswordVerificationView(
      BuildContext context, ProfileAuthenticated state) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.twoFAScanQrCode,
                  ),
                  SizedBox(height: 16),
                  QrImageView(
                    data: state.profile.otpAuthUrl!,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 16),
                  SelectableText(AppLocalizations.of(context)!
                      .twoFASecretKey(state.profile.otpBase32!)),
                  SizedBox(height: 24),
                  IntrinsicWidth(
                      child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.background,
                            border: Border.all(
                                width: 1.0, color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Column(children: [
                                CustomTextField(
                                  controller: _otpController,
                                  label: AppLocalizations.of(context)!
                                      .validationCode,
                                  obscureText: true,
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                    child: Text(
                                        AppLocalizations.of(context)!.verify),
                                    onPressed: () {
                                      BlocProvider.of<ProfileBloc>(context).add(
                                        ProfileVerifyOneTimePasswordEvent(
                                          code: _otpController.text,
                                        ),
                                      );
                                    },
                                    style: context.styles.buttonSmall),
                                SizedBox(
                                  height: 24,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .regenerateQrCode),
                                        onPressed: () {
                                          BlocProvider.of<ProfileBloc>(context)
                                              .add(
                                            ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                                          );
                                        },
                                        style: context.styles.buttonSmall),
                                    SizedBox(width: 16),
                                    ElevatedButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancel),
                                        onPressed: () {
                                          BlocProvider.of<ProfileBloc>(context)
                                              .add(
                                            ProfileDisableTwoFactorAuthenticationEvent(),
                                          );
                                        },
                                        style: context.styles.buttonSmall),
                                  ],
                                )
                              ]))))
                ])))
      ],
    ));
  }

  Widget _buildTwoFactorAuthenticationSetupView(
      BuildContext context, ProfileAuthenticated state) {
    return Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.twoFASetup,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                      child: Text(AppLocalizations.of(context)!.enable),
                      onPressed: () {
                        BlocProvider.of<ProfileBloc>(context).add(
                          ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                        );
                      },
                      style: context.styles.buttonSmall),
                ])))
      ],
    );
  }
}
