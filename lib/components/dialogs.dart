// File: lib/components/dialogs.dart
import 'package:flutter/material.dart';
import '../theme.dart'; // Assuming AppTheme is defined here

/// A reusable success dialog component.
class SuccessDialog extends StatelessWidget {
  final String message;

  const SuccessDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Success'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}

/// A reusable error dialog component with customizable title.
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const ErrorDialog({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}

/// A reusable coming soon dialog component.
class ComingSoonDialog extends StatelessWidget {
  final String feature;

  const ComingSoonDialog({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coming Soon!'),
      content: Text('$feature will be available in the next update.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }
}
