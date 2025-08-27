import 'package:flutter/material.dart';
import '../theme.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onTap;
  final double? size;

  const CategoryCard({super.key, required this.category, this.onTap, this.size});

  @override
  Widget build(BuildContext context) {
    final cardSize = size ?? 100.0;
    final colorString = category['color'] ?? '#F0F0F0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardSize,
        height: cardSize,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _parseColor(colorString),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(category['icon'] ?? '📦', style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(
              category['name'] ?? 'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF' + hex; // Add opacity for 6-digit hex
      } else if (hex.length != 8) {
        throw FormatException('Invalid hex color length');
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      debugPrint('Error parsing color $colorString: $e');
      return AppTheme.backgroundGrey;
    }
  }
}