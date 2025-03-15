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
import 'package:qr_flutter/qr_flutter.dart';

class RecoveryCodesScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Background(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BlocListener<AuthBloc, AuthState>(
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

                      if (state.message != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message!)),
                        );
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
                        return Center(child: CircularProgressIndicator());
                      } else {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!
                                .unableToLoadRecoveryCodes,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                    },
                  ),
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodesView(
      BuildContext context, AuthAuthenticatedAfterRegistration state) {
    if (state.recoveryCodes == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noRecoveryCodeAvailable
          ,
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.keepRecoveryCodesSafe,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: state.recoveryCodes!.length,
            itemBuilder: (context, index) {
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(
                    state.recoveryCodes![index],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.twoFAInvitation,
            style: TextStyle(color: Colors.white),
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
          style: TextStyle(color: Colors.white),
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
        Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(width: 1.0, color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(children: [
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
                ])))
      ],
    );
  }
}
