import 'package:flutter/material.dart';
import '../theme.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon; // Added prefixIcon parameter
  final TextEditingController? controller;
  final bool isPassword; // Parameter to identify password fields
  final bool enabled; // Enabled parameter
  final TextInputType? keyboardType; // Added keyboardType parameter

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon, // Include in constructor
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType, // Include in constructor
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscured,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType, // Use keyboardType parameter
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: widget.enabled ? Colors.grey : Colors.grey.shade400,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black87),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
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
            : widget.suffixIcon,
        prefixIcon: widget.prefixIcon, // Use prefixIcon parameter
      ),
    );
  }
}
