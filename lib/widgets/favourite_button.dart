import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../state/favourites_store.dart';

/// A heart button that adds or removes a title from favourites.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({
    super.key,
    required this.movie,
    required this.favourites,
  });

  final MovieSummary movie;
  final FavouritesStore favourites;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favourites,
      builder: (context, _) {
        final saved = favourites.contains(movie.imdbId);
        return IconButton(
          tooltip: saved ? 'Remove from favourites' : 'Add to favourites',
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          color: saved ? Theme.of(context).colorScheme.primary : null,
          onPressed: () => favourites.toggle(movie),
        );
      },
    );
  }
}
