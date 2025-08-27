import 'package:flutter/material.dart';
import 'offer_banner.dart';

class OfferSection extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const OfferSection({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OfferBanner(
      title: title,
      description: description,
      buttonText: buttonText,
      gradientColors: [
        Theme.of(context).primaryColor,
        Theme.of(context).primaryColorDark,
      ],
      onButtonPressed: onButtonPressed,
    );
  }
}
