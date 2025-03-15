import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_events.dart';
import 'package:flutteractixapp/features/auth/presentation/bloc/auth_states.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/background.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/button.dart';
import 'package:flutteractixapp/features/auth/presentation/widgets/custom_text_field.dart';

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
                              content:
                                  Text('Your validation code was correct!')),
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
                            'Unable to load recovery codes.',
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
                  text: 'Home',
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
          'No recovery codes available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Keep these recovery codes safe',
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
            'Security and privacy are our first concern. We kindly ask you to set up two-factor authentication to protect your account from brute-force attacks.',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 16),
          Button(
            text: 'Set up two-factor authentication',
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
          'Set up two-factor authentication',
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
          'Secret Key: ${state.otpBase32}',
          style: TextStyle(color: Colors.white),
        ),
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
                    label: 'Validation code',
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  Button(
                    text: 'Sign Up',
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
