import 'package:flutter/material.dart';
import '../theme.dart';

class ValidatedTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputType keyboardType;
  final int? maxLines;
  final Widget? prefixIcon; // Added prefixIcon parameter

  const ValidatedTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon, // Include in constructor
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      validator: widget.validator,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      decoration: InputDecoration(
        filled: false,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: widget.enabled ? Colors.grey : Colors.grey.shade400,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error, width: 1.5),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.error, width: 1.5),
        ),
        errorStyle: TextStyle(color: AppTheme.error, fontSize: 12),
        prefixIcon: widget.prefixIcon, // Use prefixIcon
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: widget.enabled ? Colors.grey : Colors.grey.shade400,
                ),
                onPressed: widget.enabled
                    ? () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      }
                    : null,
              )
            : null,
      ),
    );
  }
}
