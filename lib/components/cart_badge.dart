import 'package:flutter/material.dart';
import 'package:babyshop/theme.dart';

class CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? iconColor;

  const CartBadge({
    super.key,
    required this.count,
    this.onTap,
    this.badgeColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: iconColor ?? AppTheme.textPrimary,
          ),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? AppTheme.primary,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
