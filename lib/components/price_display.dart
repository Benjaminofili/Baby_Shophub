import 'package:flutter/material.dart';
import '../theme.dart';

class PriceDisplay extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final bool showCurrency;
  final String currency;

  const PriceDisplay({
    super.key,
    required this.price,
    this.originalPrice,
    this.priceStyle,
    this.originalPriceStyle,
    this.showCurrency = true,
    this.currency = '₦', // FIXED: Correct Naira symbol
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = originalPrice != null && originalPrice! > price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
      children: [
        Text(
          '${showCurrency ? currency : ''}${price.toStringAsFixed(2)}',
          style:
              priceStyle ??
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: hasDiscount ? AppTheme.primary : AppTheme.textPrimary,
              ),
        ),
        if (hasDiscount) ...[
          SizedBox(height: 2), // Small spacing
          Text(
            '${showCurrency ? currency : ''}${originalPrice!.toStringAsFixed(2)}',
            style:
                originalPriceStyle ??
                TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
          ),
        ],
      ],
    );
  }
}
