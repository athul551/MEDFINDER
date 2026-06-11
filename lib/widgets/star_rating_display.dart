import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 18,
    this.showValue = false,
    this.color,
  });

  final double rating;
  final double size;
  final bool showValue;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber.shade700;
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.25;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          IconData icon;
          if (index < fullStars) {
            icon = Icons.star_rounded;
          } else if (index == fullStars && hasHalf) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          return Icon(icon, color: starColor, size: size);
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.8,
            ),
          ),
        ],
      ],
    );
  }
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 36,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final value = index + 1;
            return IconButton(
              onPressed: () => onChanged(value),
              icon: Icon(
                value <= rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: Colors.amber.shade700,
                size: size,
              ),
            );
          }),
        ),
        Text(
          ReviewRatingLabels.forRating(rating),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
