import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../state/favourites_store.dart';
import '../widgets/message_view.dart';
import '../widgets/ratings_chart.dart';
import 'details_screen.dart';

/// Screen 4: every episode of a TV series, season by season, with ratings.
class EpisodeGuideScreen extends StatelessWidget {
  const EpisodeGuideScreen({
    super.key,
    required this.series,
    required this.totalSeasons,
    required this.service,
    required this.favourites,
  });

  final MovieSummary series;
  final int totalSeasons;
  final OmdbService service;
  final FavouritesStore favourites;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: totalSeasons,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${series.title}: Episode Guide'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (var s = 1; s <= totalSeasons; s++) Tab(text: 'Season $s'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (var s = 1; s <= totalSeasons; s++)
              _SeasonView(
                key: PageStorageKey('season-$s'),
                series: series,
                seasonNumber: s,
                service: service,
                favourites: favourites,
              ),
          ],
        ),
      ),
    );
  }
}

class _SeasonView extends StatefulWidget {
  const _SeasonView({
    super.key,
    required this.series,
    required this.seasonNumber,
    required this.service,
    required this.favourites,
  });

  final MovieSummary series;
  final int seasonNumber;
  final OmdbService service;
  final FavouritesStore favourites;

  @override
  State<_SeasonView> createState() => _SeasonViewState();
}

/// Keeps each season loaded when switching tabs, so it isn't fetched twice.
class _SeasonViewState extends State<_SeasonView>
    with AutomaticKeepAliveClientMixin {
  late Future<Season> _season;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _season = widget.service.season(widget.series.imdbId, widget.seasonNumber);
  }

  void _openEpisode(Episode episode) {
    final released = episode.released ?? '';
    final summary = MovieSummary(
      imdbId: episode.imdbId,
      title: episode.title,
      year: released.length >= 4 ? released.substring(0, 4) : '',
      type: 'episode',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          movie: summary,
          service: widget.service,
          favourites: widget.favourites,
          heroTag: 'episode-${episode.imdbId}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Season>(
      future: _season,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.error_outline,
            title: 'Could not load this season',
            message: '${snapshot.error}',
            actionLabel: 'Try again',
            onAction: () => setState(_load),
          );
        }
        final season = snapshot.data;
        if (season == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (season.episodes.isEmpty) {
          return const MessageView(
            icon: Icons.tv_off,
            title: 'No episodes yet',
            message: 'There is no episode information for this season.',
          );
        }
        return _buildSeason(context, season);
      },
    );
  }

  Widget _buildSeason(BuildContext context, Season season) {
    final best = season.bestEpisode;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SeasonSummary(season: season),
            if (season.rated.length >= 2) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RatingsChart(episodes: season.episodes),
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (final episode in season.episodes)
              _EpisodeTile(
                episode: episode,
                isBest: best != null && episode.imdbId == best.imdbId,
                onTap: episode.imdbId.isEmpty
                    ? null
                    : () => _openEpisode(episode),
              ),
          ],
        ),
      ),
    );
  }
}

/// Average rating, best and lowest episode for the season.
class _SeasonSummary extends StatelessWidget {
  const _SeasonSummary({required this.season});

  final Season season;

  @override
  Widget build(BuildContext context) {
    final average = season.averageRating;
    final best = season.bestEpisode;
    final worst = season.worstEpisode;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          label: 'Episodes',
          value: '${season.episodes.length}',
          icon: Icons.video_library_outlined,
        ),
        if (average != null)
          _StatCard(
            label: 'Average rating',
            value: average.toStringAsFixed(1),
            icon: Icons.star_half,
          ),
        if (best != null)
          _StatCard(
            label: 'Best: E${best.number}',
            value: best.rating!.toStringAsFixed(1),
            icon: Icons.emoji_events_outlined,
          ),
        if (worst != null && worst.imdbId != best?.imdbId)
          _StatCard(
            label: 'Lowest: E${worst.number}',
            value: worst.rating!.toStringAsFixed(1),
            icon: Icons.trending_down,
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.isBest,
    required this.onTap,
  });

  final Episode episode;
  final bool isBest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Text('${episode.number}')),
        title: Row(
          children: [
            Flexible(
              child: Text(episode.title, overflow: TextOverflow.ellipsis),
            ),
            if (isBest) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Highest rated episode this season',
                child: Icon(
                  Icons.star,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        subtitle: episode.released == null ? null : Text(episode.released!),
        trailing: RatingBadge(rating: episode.rating),
      ),
    );
  }
}
