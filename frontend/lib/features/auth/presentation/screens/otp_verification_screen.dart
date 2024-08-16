import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:reallystick/features/auth/presentation/bloc/auth_states.dart';
import 'package:reallystick/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:reallystick/features/auth/presentation/widgets/submit_button.dart';

class OtpVerificationScreen extends StatelessWidget {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Navigate to the next screen after successful OTP verification
              Navigator.pushNamed(context, '/');
            } else if (state is AuthFailure) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                controller: _otpController,
                label: 'Enter OTP',
                obscureText: false,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24),
              SubmitButton(
                text: 'Verify OTP',
                onPressed: () {
                  // BlocProvider.of<AuthBloc>(context).add(
                  //   AuthOTPVerified(
                  //     userId: _otpController.,
                  //     otp: _otpController.text,
                  //   ),
                  // );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
