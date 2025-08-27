// lib/screens/support.dart
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../components/Validatetextfield.dart'; // Custom text field with validation
import '../../services/supabase_service.dart'; // Service to submit feedback to Supabase

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false; // Tracks if feedback is being submitted

  @override
  void dispose() {
    // Clean up controllers when the screen is disposed
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Submits the feedback to Supabase
  Future<void> _submitFeedback() async {
    // Check if fields are empty
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in both subject and message fields');
      return;
    }

    // Validate minimum and maximum lengths
    if (_subjectController.text.trim().length < 5) {
      _showErrorSnackBar('Subject must be at least 5 characters long');
      return;
    }
    if (_messageController.text.trim().length < 10) {
      _showErrorSnackBar('Message must be at least 10 characters long');
      return;
    }
    if (_subjectController.text.trim().length > 200) {
      _showErrorSnackBar('Subject must be less than 200 characters');
      return;
    }
    if (_messageController.text.trim().length > 2000) {
      _showErrorSnackBar('Message must be less than 2000 characters');
      return;
    }

    // Show loading state
    setState(() => _isSubmitting = true);

    try {
      // Send feedback to Supabase
      await SupabaseService.submitFeedback(
        _subjectController.text.trim(),
        _messageController.text.trim(),
      );

      if (mounted) {
        // Reset form and hide loading state
        setState(() => _isSubmitting = false);
        _subjectController.clear();
        _messageController.clear();

        // Show success message
        _showSuccessSnackBar('Your feedback has been submitted successfully! We\'ll review it soon.');

        // Return to profile after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Hide loading state
        setState(() => _isSubmitting = false);

        // Customize error message based on exception
        String errorMessage = 'Failed to submit feedback. Please try again.';
        if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please log in to submit feedback.';
        } else if (e.toString().contains('Failed to submit feedback')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }

        _showErrorSnackBar(errorMessage);
      }
    }
  }

  // Displays an error message as a snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, // Makes snackbar float above content
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Displays a success message as a snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Builds a widget to show the character count for text fields
  Widget _buildCharacterCounter(String text, int maxLength) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Text(
        '${text.length}/$maxLength',
        style: TextStyle(
          fontSize: 12,
          color: text.length > maxLength ? Colors.red : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight, // Light background from theme
      appBar: AppBar(
        title: const Text('Feedback & Support'),
        backgroundColor: AppTheme.primary, // Primary color from theme
        foregroundColor: Colors.white,
        elevation: 0, // No shadow for a cleaner look
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary)) // Loading indicator
          : Padding(
        padding: const EdgeInsets.all(20.0), // Consistent padding
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
            children: [
              // Header text
              const Text(
                'How can we help?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Report an issue, provide feedback, or contact support.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Subject input field
              ValidatedTextField(
                hintText: 'Subject (5-200 characters)',
                controller: _subjectController,
                validator: (value) {
                  if (value!.isEmpty) return 'Subject is required';
                  if (value.trim().length < 5) return 'Subject must be at least 5 characters';
                  if (value.trim().length > 200) return 'Subject must be less than 200 characters';
                  return null;
                },
              ),
              _buildCharacterCounter(_subjectController.text, 200),

              const SizedBox(height: 24),

              // Message input field
              ValidatedTextField(
                hintText: 'Message (10-2000 characters)',
                controller: _messageController,
                maxLines: 6, // Allows multiple lines for detailed feedback
                validator: (value) {
                  if (value!.isEmpty) return 'Message is required';
                  if (value.trim().length < 10) return 'Message must be at least 10 characters';
                  if (value.trim().length > 2000) return 'Message must be less than 2000 characters';
                  return null;
                },
              ),
              _buildCharacterCounter(_messageController.text, 2000),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity, // Full width button
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional help section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1), // Light tint of primary color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2), // Subtle border
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Need immediate help?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For urgent matters, you can also reach us through:',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Email: support@babyshoppe.com\n• Phone: +234 XXX XXX XXXX\n• Live Chat (available 9AM-6PM)',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}