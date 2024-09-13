import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:flutteractixapp/features/profile/presentation/utils/error_mapper.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RecoveryCodesScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
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
                          if (state is AuthAuthenticatedAfterRegistration) {
                            if (state.hasVerifiedOtp) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(AppLocalizations.of(context)!
                                        .validationCodeCorrect)),
                              );
                              context.go('/home');
                            } else {
                              context.go('/recovery-codes');
                            }
                          } else if (state is AuthOtpVerify) {
                            _otpController.text = '';

                            if (state.error != null) {
                              final errorMessage =
                                  getProfileErrorMessage(context, state.error!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(errorMessage)));
                            }
                          }
                        },
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthAuthenticatedAfterRegistration) {
                              return _buildRecoveryCodesView(context, state);
                            } else if (state is AuthOtpGenerate) {
                              return _buildOtpSetupView(context, state);
                            } else if (state is AuthLoading) {
                              return CircularProgressIndicator(
                                color: Colors.black,
                              );
                            } else {
                              return Text(
                                AppLocalizations.of(context)!
                                    .unableToLoadRecoveryCodes,
                              );
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
              )
            ]),
      ]),
    );
  }

  Widget _buildRecoveryCodesView(
      BuildContext context, AuthAuthenticatedAfterRegistration state) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recovery codes copied to clipboard'),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.twoFAInvitation,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Button(
            text: AppLocalizations.of(context)!.goToTwoFASetup,
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(
                AuthOtpGenerationRequested(),
              );
            },
            size: ButtonSize.small,
            isPrimary: true,
          ),
        ],
      );
    }
  }

  Widget _buildOtpSetupView(BuildContext context, AuthOtpGenerate state) {
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
        SelectableText(
            AppLocalizations.of(context)!.twoFASecretKey(state.otpBase32)),
        SizedBox(height: 24),
        CustomTextField(
          controller: _otpController,
          label: AppLocalizations.of(context)!.validationCode,
          obscureText: true,
        ),
        SizedBox(height: 24),
        Button(
          text: AppLocalizations.of(context)!.signUp,
          onPressed: () {
            BlocProvider.of<AuthBloc>(context).add(
              AuthOtpVerificationRequested(
                otpBase32: state.otpBase32,
                otpAuthUrl: state.otpAuthUrl,
                code: _otpController.text,
              ),
            );
          },
          isPrimary: true,
          size: ButtonSize.small,
        ),
      ],
    );
  }
}
