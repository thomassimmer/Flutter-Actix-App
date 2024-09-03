import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/bloc/profile_states.dart';
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
          child: BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
            if (state.message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          }, child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileAuthenticated) {
                if (state.profile.otpVerified) {
                  return _buildOtpRegenerateOrDisableView(context, state);
                } else if (state.profile.otpAuthUrl != null) {
                  return _buildOtpVerificationView(context, state);
                } else {
                  return _buildOtpSetupView(context, state);
                }
              } else if (state is ProfileLoading) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(child: Text(AppLocalizations.of(context)!.failedToLoadProfile));
              }
            },
          ))),
    );
  }

  Widget _buildOtpRegenerateOrDisableView(
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
                      Button(
                        text: AppLocalizations.of(context)!.generateNewQrCode,
                        onPressed: () {
                          BlocProvider.of<ProfileBloc>(context).add(
                            ProfileOtpGenerationRequested(),
                          );
                        },
                        isPrimary: true,
                        size: ButtonSize.small,
                      ),
                      SizedBox(width: 16),
                      Button(
                        text: AppLocalizations.of(context)!.disableTwoFA,
                        onPressed: () {
                          BlocProvider.of<ProfileBloc>(context).add(
                            ProfileOtpDisablingRequested(),
                          );
                        },
                        isPrimary: true,
                        size: ButtonSize.small,
                      ),
                    ],
                  )
                ])))
      ],
    );
  }

  Widget _buildOtpVerificationView(
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
                  ),
                  SizedBox(height: 16),
                  SelectableText(AppLocalizations.of(context)!
                      .twoFASecretKey(state.profile.otpBase32!)),
                  SizedBox(height: 24),
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
                              controller: _otpController,
                              label:
                                  AppLocalizations.of(context)!.validationCodeField,
                              obscureText: true,
                            ),
                            SizedBox(height: 24),
                            Button(
                              text: AppLocalizations.of(context)!.verify,
                              onPressed: () {
                                BlocProvider.of<ProfileBloc>(context).add(
                                  ProfileOtpVerificationRequested(
                                    code: _otpController.text,
                                  ),
                                );
                              },
                              isPrimary: true,
                              size: ButtonSize.small,
                            ),
                            SizedBox(
                              height: 24,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Button(
                                  text: AppLocalizations.of(context)!
                                      .regenerateQrCode,
                                  onPressed: () {
                                    BlocProvider.of<ProfileBloc>(context).add(
                                      ProfileOtpGenerationRequested(),
                                    );
                                  },
                                  isPrimary: true,
                                  size: ButtonSize.small,
                                ),
                                SizedBox(width: 16),
                                Button(
                                  text: AppLocalizations.of(context)!.cancel,
                                  onPressed: () {
                                    BlocProvider.of<ProfileBloc>(context).add(
                                      ProfileOtpDisablingRequested(),
                                    );
                                  },
                                  isPrimary: true,
                                  size: ButtonSize.small,
                                ),
                              ],
                            )
                          ])))
                ])))
      ],
    ));
  }

  Widget _buildOtpSetupView(BuildContext context, ProfileAuthenticated state) {
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
                  Button(
                    text: AppLocalizations.of(context)!.enable,
                    onPressed: () {
                      BlocProvider.of<ProfileBloc>(context).add(
                        ProfileOtpGenerationRequested(),
                      );
                    },
                    isPrimary: true,
                    size: ButtonSize.small,
                  ),
                ])))
      ],
    );
  }
}
