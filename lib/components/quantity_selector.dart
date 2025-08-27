import 'package:flutter/material.dart';
import '../theme.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int>? onQuantityChanged;
  final int minQuantity;
  final int maxQuantity;
  final bool enabled;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.onQuantityChanged,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onPressed: enabled && quantity > minQuantity
                ? () => onQuantityChanged?.call(quantity - 1)
                : null,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onPressed: enabled && quantity < maxQuantity
                ? () => onQuantityChanged?.call(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
