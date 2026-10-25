import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../state/favourites_store.dart';
import '../widgets/favourite_button.dart';
import '../widgets/message_view.dart';
import '../widgets/poster.dart';
import 'episode_guide_screen.dart';

/// Screen 2: full information about one film or series.
///
/// The poster and title are shown straight away from the search result,
/// while the rest of the details load in the background.
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({
    super.key,
    required this.movie,
    required this.service,
    required this.favourites,
    required this.heroTag,
  });

  final MovieSummary movie;
  final OmdbService service;
  final FavouritesStore favourites;
  final String heroTag;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Future<MovieDetails> _details;

  @override
  void initState() {
    super.initState();
    _details = widget.service.details(widget.movie.imdbId);
  }

  void _retry() {
    setState(() => _details = widget.service.details(widget.movie.imdbId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        actions: [
          FavouriteButton(movie: widget.movie, favourites: widget.favourites),
        ],
      ),
      body: FutureBuilder<MovieDetails>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              title: 'Could not load details',
              message: '${snapshot.error}',
              actionLabel: 'Try again',
              onAction: _retry,
            );
          }
          return _DetailsBody(
            movie: widget.movie,
            details: snapshot.data,
            heroTag: widget.heroTag,
            service: widget.service,
            favourites: widget.favourites,
          );
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.movie,
    required this.details,
    required this.heroTag,
    required this.service,
    required this.favourites,
  });

  final MovieSummary movie;
  final OmdbService service;
  final FavouritesStore favourites;

  /// Null while the details are still loading.
  final MovieDetails? details;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = this.details;

    final poster = Hero(
      tag: heroTag,
      child: Poster(url: movie.posterUrl, width: 200, height: 300),
    );

    final subtitle = [
      movie.year,
      details?.rated,
      details?.runtime,
    ].whereType<String>().where((part) => part.isNotEmpty).join('  ·  ');

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (details == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          ..._buildInfo(context, details),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Side by side on wide screens, stacked on phones.
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    poster,
                    const SizedBox(width: 32),
                    Expanded(child: info),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: poster),
                  const SizedBox(height: 24),
                  info,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfo(BuildContext context, MovieDetails details) {
    final facts = {
      'Director': details.director,
      'Writer': details.writer,
      'Starring': details.actors,
      'Released': details.released,
      'Language': details.language,
      'Awards': details.awards,
    };

    final totalSeasons = details.totalSeasons;
    return [
      if (details.hasEpisodeGuide && totalSeasons != null) ...[
        FilledButton.icon(
          icon: const Icon(Icons.bar_chart),
          label: Text(
            'Episode guide · $totalSeasons '
            '${totalSeasons == 1 ? 'season' : 'seasons'}',
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EpisodeGuideScreen(
                series: movie,
                totalSeasons: totalSeasons,
                service: service,
                favourites: favourites,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (details.genres.isNotEmpty)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in details.genres) Chip(label: Text(genre)),
          ],
        ),
      if (details.ratings.isNotEmpty)
        _Section(
          title: 'Ratings',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final rating in details.ratings) _RatingCard(rating: rating),
            ],
          ),
        ),
      if (details.plot != null)
        _Section(
          title: 'Plot',
          child: Text(
            details.plot!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      _Section(
        title: 'Details',
        child: Column(
          children: [
            for (final fact in facts.entries)
              if (fact.value != null)
                _FactRow(label: fact.key, value: fact.value!),
          ],
        ),
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            rating.source,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
