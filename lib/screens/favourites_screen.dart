import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../state/favourites_store.dart';
import '../widgets/message_view.dart';
import '../widgets/movie_tile.dart';
import 'details_screen.dart';

/// Screen 3: the user's saved favourites. Swipe left to remove one.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({
    super.key,
    required this.service,
    required this.favourites,
  });

  final OmdbService service;
  final FavouritesStore favourites;

  void _openDetails(BuildContext context, MovieSummary movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          movie: movie,
          service: service,
          favourites: favourites,
          heroTag: 'favourite-${movie.imdbId}',
        ),
      ),
    );
  }

  void _remove(BuildContext context, MovieSummary movie) {
    favourites.toggle(movie);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${movie.title}" from favourites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => favourites.toggle(movie),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: ListenableBuilder(
        listenable: favourites,
        builder: (context, _) {
          final items = favourites.items;
          if (items.isEmpty) {
            return const MessageView(
              icon: Icons.favorite_border,
              title: 'No favourites yet',
              message: 'Tap the heart on any film or series to save it here.',
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final movie = items[index];
                  return Dismissible(
                    key: ValueKey(movie.imdbId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(Icons.delete_outline, color: errorColor),
                    ),
                    onDismissed: (_) => _remove(context, movie),
                    child: MovieTile(
                      movie: movie,
                      favourites: favourites,
                      heroTag: 'favourite-${movie.imdbId}',
                      onTap: () => _openDetails(context, movie),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
