// lib/screens/help.dart
import 'package:flutter/material.dart';
import '../../theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'How do I place an order?',
              answer: 'Go to the cart, review your items, and click "Proceed to Checkout". Follow the payment steps to complete your order.',
            ),
            _buildFAQItem(
              question: 'What payment methods are accepted?',
              answer: 'We accept Visa, MasterCard, and mobile payments via Paystack.',
            ),
            _buildFAQItem(
              question: 'How can I track my order?',
              answer: 'Use the "Track Order" option in your profile and enter your tracking number.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              context: context,
              icon: Icons.email,
              text: 'support@baby.shop',
              onTap: () => _launchEmail(context, 'support@baby.shop'),
            ),
            _buildContactItem(
              context: context,
              icon: Icons.phone,
              text: '+234 800 123 4567',
              onTap: () => _launchPhone(context, '+2348001234567'),
            ),
            _buildContactItem(
              context: context,
              icon: Icons.feedback,
              text: 'Send Feedback',
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context, // Added context parameter
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _launchEmail(BuildContext context, String email) {
    // Requires url_launcher package: https://pub.dev/packages/url_launcher
    // Example: launch('mailto:$email');
    _showComingSoonDialog(context, 'Email');
  }

  void _launchPhone(BuildContext context, String phone) {
    // Requires url_launcher package
    // Example: launch('tel:$phone');
    _showComingSoonDialog(context, 'Phone Call');
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon! Stay tuned for updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}