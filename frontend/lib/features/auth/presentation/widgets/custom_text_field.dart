import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLength;
  final String? errorText;
  final void Function(String)? onChanged;

  CustomTextField(
      {required this.controller,
      required this.label,
      this.keyboardType = TextInputType.text,
      this.validator,
      this.obscureText = false,
      this.maxLength,
      this.errorText,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.0,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorMaxLines: 10,
          floatingLabelStyle: TextStyle(
            color:
                Colors.blue.shade200, // Set the floating label color to white
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          counterText: '',
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.blue.shade900,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.blue.shade200,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.red.shade200,
              width: 2.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Colors.red.shade900,
            ),
          ),
          errorText: errorText,
        ),
        validator: validator,
      ),
    );
  }
}
