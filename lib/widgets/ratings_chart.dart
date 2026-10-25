import 'package:flutter/material.dart';

import '../models/movie.dart';

/// Colour for an IMDb rating: green for great, amber for good,
/// orange for weaker episodes and grey when there is no rating.
Color ratingColour(double? rating) {
  if (rating == null) return Colors.grey;
  if (rating >= 8.5) return Colors.green.shade600;
  if (rating >= 7.5) return Colors.amber.shade700;
  return Colors.deepOrange;
}

/// A small coloured badge showing an episode's rating.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating});

  final double? rating;

  @override
  Widget build(BuildContext context) {
    final rating = this.rating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ratingColour(rating),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rating == null ? 'N/A' : rating.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// A bar chart of episode ratings across a season.
///
/// The axis starts just below the lowest rating (not at 0), so small
/// differences between episodes are easy to see. The range is shown
/// in the caption so the chart is not misleading.
class RatingsChart extends StatelessWidget {
  const RatingsChart({super.key, required this.episodes});

  final List<Episode> episodes;

  static const _chartHeight = 140.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratings = episodes.map((e) => e.rating).whereType<double>();
    final lowest = ratings.reduce((a, b) => a < b ? a : b);
    final axisMin = (lowest - 1).floorToDouble().clamp(0.0, 9.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Episode ratings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'IMDb rating, scale ${axisMin.toStringAsFixed(0)}–10',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final episode in episodes)
                Expanded(
                  child: Tooltip(
                    message: episode.rating == null
                        ? 'E${episode.number}: ${episode.title} (no rating)'
                        : 'E${episode.number}: ${episode.title} '
                              '(${episode.rating!.toStringAsFixed(1)})',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: _barHeight(episode.rating, axisMin),
                        decoration: BoxDecoration(
                          color: ratingColour(episode.rating),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final episode in episodes)
              Expanded(
                child: Text(
                  episodes.length <= 16 || episode.number % 5 == 0
                      ? '${episode.number}'
                      : '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }

  double _barHeight(double? rating, double axisMin) {
    if (rating == null) return 4;
    final fraction = (rating - axisMin) / (10 - axisMin);
    return (fraction * _chartHeight).clamp(4.0, _chartHeight);
  }
}
