import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/core/ui/extensions.dart';
import 'package:flutteractixapp/core/widgets/app_logo.dart';
import 'package:flutteractixapp/core/widgets/custom_container.dart';
import 'package:flutteractixapp/core/widgets/custom_text_field.dart';
import 'package:flutteractixapp/core/widgets/global_snack_bar.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RecoveryCodesScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Background(),
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
                              GlobalSnackBar.show(context, state.message);

                              if (state
                                  is AuthAuthenticatedAfterRegistrationState) {
                                if (state.hasVerifiedOtp) {
                                  context.goNamed('home');
                                } else {
                                  context.goNamed('recovery-codes');
                                }
                              } else if (state
                                  is AuthVerifyOneTimePasswordState) {
                                _otpController.text = '';
                              }
                            },
                            builder: (context, state) {
                              if (state
                                  is AuthAuthenticatedAfterRegistrationState) {
                                return _buildRecoveryCodesView(context, state);
                              } else if (state
                                  is AuthGenerateTwoFactorAuthenticationConfigState) {
                                return _buildTwoFactorAuthenticationSetupView(
                                    context, state);
                              } else if (state is AuthLoadingState) {
                                return _buildLoadingScreen(context, state);
                              } else {
                                return _buildErrorScreen(context, state);
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.goNamed('home');
                          },
                          child: Text(AppLocalizations.of(context)!.home),
                        )
                      ])))),
    ]));
  }

  Widget _buildErrorScreen(BuildContext context, AuthState state) {
    return Column(children: [
      Text(
        AppLocalizations.of(context)!.unableToLoadRecoveryCodes,
      )
    ]);
  }

  Widget _buildLoadingScreen(BuildContext context, AuthState state) {
    return Column(children: [CircularProgressIndicator()]);
  }

  Widget _buildRecoveryCodesView(
      BuildContext context, AuthAuthenticatedAfterRegistrationState state) {
    if (state.recoveryCodes == null) {
      return Column(children: [
        Text(
          AppLocalizations.of(context)!.noRecoveryCodeAvailable,
        ),
      ]);
    } else {
      return Column(
        children: [
          Text(
            AppLocalizations.of(context)!.keepRecoveryCodesSafe,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          SelectionArea(
            child: Column(
              children: [
                for (var recoveryCode in state.recoveryCodes!)
                  SelectableText(
                    recoveryCode,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 12,
            ),
            onPressed: () {
              // Concatenate all recovery codes and copy them to the clipboard
              final codes = state.recoveryCodes!.join('\n');
              Clipboard.setData(ClipboardData(text: codes));

              // Create an InfoMessage for successfully copying the codes
              final message = InfoMessage('recoveryCodesCopied');
              GlobalSnackBar.show(context, message);
            },
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.twoFAInvitation,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(
                AuthGenerateTwoFactorAuthenticationConfigEvent(),
              );
            },
            style: context.styles.buttonSmall,
            child: Text(AppLocalizations.of(context)!.goToTwoFASetup),
          ),
        ],
      );
    }
  }

  Widget _buildTwoFactorAuthenticationSetupView(BuildContext context,
      AuthGenerateTwoFactorAuthenticationConfigState state) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.twoFASetup,
        ),
        SizedBox(height: 16),
        QrImageView(
          data: state.otpAuthUrl,
          version: QrVersions.auto,
          size: 200.0,
        ),
        SizedBox(height: 16),
        Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center, // Align the elements to the center
            spacing: 8.0, // Add spacing between elements
            direction:
                Axis.horizontal, // Horizontal direction for the initial layout
            children: [
              SelectableText(AppLocalizations.of(context)!
                  .twoFASecretKey(state.otpBase32)),
              IconButton(
                icon: Icon(
                  Icons.copy,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.otpBase32));

                  // Create an InfoMessage for successfully copying the codes
                  final message = InfoMessage('qrCodeSecretKeyCopied');
                  GlobalSnackBar.show(context, message);
                },
              )
            ]),
        SizedBox(height: 24),
        CustomTextField(
          controller: _otpController,
          label: AppLocalizations.of(context)!.validationCode,
          obscureText: true,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthVerifyOneTimePasswordEvent(
                otpBase32: state.otpBase32,
                otpAuthUrl: state.otpAuthUrl,
                code: _otpController.text,
              ),
            );
          },
          child: Text(AppLocalizations.of(context)!.verify),
        ),
      ],
    );
  }
}
