import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../state/favourites_store.dart';
import 'favourite_button.dart';
import 'poster.dart';

/// One row in a list of films: poster, title, year, type and a heart button.
class MovieTile extends StatelessWidget {
  const MovieTile({
    super.key,
    required this.movie,
    required this.favourites,
    required this.heroTag,
    required this.onTap,
  });

  final MovieSummary movie;
  final FavouritesStore favourites;

  /// Unique tag so the poster can animate into the details screen.
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                child: Poster(url: movie.posterUrl, width: 60, height: 90),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        movie.year,
                        movie.typeLabel,
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FavouriteButton(movie: movie, favourites: favourites),
            ],
          ),
        ),
      ),
    );
  }
}
