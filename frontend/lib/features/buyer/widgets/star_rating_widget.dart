import 'package:flutter/material.dart';

class StarRatingWidget extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final bool interactive;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.interactive = true,
    this.size = 40.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _currentRating;

        return widget.interactive
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _currentRating = starIndex;
                  });
                  widget.onRatingChanged(starIndex);
                },
                child: _buildStar(isFilled),
              )
            : _buildStar(isFilled);
      }),
    );
  }

  Widget _buildStar(bool isFilled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Icon(
        isFilled ? Icons.star : Icons.star_outline,
        color: isFilled ? widget.activeColor : widget.inactiveColor,
        size: widget.size,
      ),
    );
  }
}

/// Display-only star rating widget
class DisplayStarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool showLabel;

  const DisplayStarRating({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.color = Colors.amber,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= rating.ceil();
            final isHalf = starIndex == rating.ceil() && rating % 1 != 0;

            return Icon(
              isFilled
                  ? Icons.star
                  : isHalf
                      ? Icons.star_half
                      : Icons.star_outline,
              color: color,
              size: size,
            );
          }),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ]
      ],
    );
  }
}
