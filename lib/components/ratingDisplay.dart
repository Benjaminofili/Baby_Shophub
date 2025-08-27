import 'package:flutter/material.dart';
import '../theme.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double starSize;
  final Color? starColor;
  final Color? textColor;
  final bool showReviewCount;
  final bool showRatingText;
  final MainAxisSize mainAxisSize;
  final TextStyle? textStyle;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 16,
    this.starColor,
    this.textColor,
    this.showReviewCount = true,
    this.showRatingText = false,
    this.mainAxisSize = MainAxisSize.min,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0.0, 5.0);
    final effectiveTextColor = textColor ?? AppTheme.textSecondary;
    final effectiveStarColor = starColor ?? Colors.amber;

    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        // Star Rating Display
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < clampedRating.floor()) {
              // Full star
              return Icon(
                Icons.star,
                size: starSize,
                color: effectiveStarColor,
              );
            } else if (index < clampedRating) {
              // Half star
              return Icon(
                Icons.star_half,
                size: starSize,
                color: effectiveStarColor,
              );
            } else {
              // Empty star
              return Icon(
                Icons.star_border,
                size: starSize,
                color: effectiveStarColor.withValues(alpha: 0.3),
              );
            }
          }),
        ),

        // Rating Text (optional)
        if (showRatingText && clampedRating > 0) ...[
          const SizedBox(width: 4),
          Text(
            clampedRating.toStringAsFixed(1),
            style:
                textStyle ??
                TextStyle(
                  fontSize: starSize * 0.8,
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],

        // Review Count (optional)
        if (showReviewCount && reviewCount != null && reviewCount! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '(${_formatReviewCount(reviewCount!)})',
            style:
                textStyle ??
                TextStyle(fontSize: starSize * 0.75, color: effectiveTextColor),
          ),
        ],
      ],
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    }
    return count.toString();
  }
}

// Alternative compact rating display for tight spaces
class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final Color? color;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: Colors.amber),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.85,
            color: effectiveColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (reviewCount != null && reviewCount! > 0) ...[
          Text(
            ' (${reviewCount! > 999 ? '999+' : reviewCount})',
            style: TextStyle(fontSize: size * 0.8, color: effectiveColor),
          ),
        ],
      ],
    );
  }
}

// Rating display with background for emphasis
class BadgeRatingDisplay extends StatelessWidget {
  final double rating;
  final Color? backgroundColor;
  final Color? textColor;
  final double padding;

  const BadgeRatingDisplay({
    super.key,
    required this.rating,
    this.backgroundColor,
    this.textColor,
    this.padding = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
