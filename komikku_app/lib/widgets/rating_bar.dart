import 'package:flutter/material.dart';

/// Widget reusable Rating Bar bintang (1..5)
/// Mendukung mode tampilan (read-only) maupun interaktif (dapat diklik).
class RatingBar extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color color;
  final bool isInteractive;
  final ValueChanged<int>? onRatingChanged;

  const RatingBar({
    super.key,
    required this.rating,
    this.starSize = 20,
    this.color = Colors.amber,
    this.isInteractive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && !isFilled;

        final iconData = isFilled
            ? Icons.star_rounded
            : isHalf
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;

        if (isInteractive) {
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (onRatingChanged != null) {
                onRatingChanged!(starValue);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                iconData,
                color: color,
                size: starSize,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          child: Icon(
            iconData,
            color: color,
            size: starSize,
          ),
        );
      }),
    );
  }
}
