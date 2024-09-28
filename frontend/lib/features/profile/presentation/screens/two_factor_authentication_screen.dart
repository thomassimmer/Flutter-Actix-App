import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/custom_container.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/profile/profile_states.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorAuthenticationScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.twoFA),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
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
                child: Text(AppLocalizations.of(context)!.failedToLoadProfile));
          }
        },
      ),
    );
  }

  Widget _buildTwoFactorAuthenticationRegenerateConfigOrDisableView(
      BuildContext context, ProfileAuthenticated state) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.twoFAIsWellSetup,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          BlocProvider.of<ProfileBloc>(context).add(
                            ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                          );
                        },
                        style: context.styles.buttonSmall,
                        child: Text(
                            AppLocalizations.of(context)!.generateNewQrCode),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          BlocProvider.of<ProfileBloc>(context).add(
                            ProfileDisableTwoFactorAuthenticationEvent(),
                          );
                        },
                        style: context.styles.buttonSmall,
                        child: Text(AppLocalizations.of(context)!.disableTwoFA),
                      ),
                    ],
                  )
                ])))
      ],
    ));
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
                  Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment
                          .center, // Align the elements to the center
                      spacing: 8.0, // Add spacing between elements
                      direction: Axis
                          .horizontal, // Horizontal direction for the initial layout
                      children: [
                        SelectableText(AppLocalizations.of(context)!
                            .twoFASecretKey(state.profile.otpBase32!)),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: state.profile.otpBase32!));

                            // Create an InfoMessage for successfully copying the codes
                            final message =
                                InfoMessage('qrCodeSecretKeyCopied');
                            GlobalSnackBar.show(context, message);
                          },
                        )
                      ]),
                  SizedBox(height: 24),
                  IntrinsicWidth(
                      child: CustomContainer(
                          child: Column(children: [
                    CustomTextField(
                      controller: _otpController,
                      label: AppLocalizations.of(context)!.validationCode,
                      obscureText: true,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        BlocProvider.of<ProfileBloc>(context).add(
                          ProfileVerifyOneTimePasswordEvent(
                            code: _otpController.text,
                          ),
                        );
                      },
                      style: context.styles.buttonMedium,
                      child: Text(AppLocalizations.of(context)!.verify),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            BlocProvider.of<ProfileBloc>(context).add(
                              ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                            );
                          },
                          style: context.styles.buttonSmall,
                          child: Text(
                              AppLocalizations.of(context)!.regenerateQrCode),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            BlocProvider.of<ProfileBloc>(context).add(
                              ProfileDisableTwoFactorAuthenticationEvent(),
                            );
                          },
                          style: context.styles.buttonSmall,
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ],
                    )
                  ])))
                ])))
      ],
    ));
  }

  Widget _buildTwoFactorAuthenticationSetupView(
      BuildContext context, ProfileAuthenticated state) {
    return SingleChildScrollView(
        child: Column(
      children: [
        Center(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  Text(
                    AppLocalizations.of(context)!.twoFASetup,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      BlocProvider.of<ProfileBloc>(context).add(
                        ProfileGenerateTwoFactorAuthenticationConfigEvent(),
                      );
                    },
                    style: context.styles.buttonMedium,
                    child: Text(AppLocalizations.of(context)!.enable),
                  ),
                ])))
      ],
    ));
  }
}
