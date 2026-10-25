import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../state/favourites_store.dart';
import '../widgets/message_view.dart';
import '../widgets/movie_tile.dart';
import 'details_screen.dart';

/// Screen 1: search for films and series and browse the results.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.service,
    required this.favourites,
  });

  final OmdbService service;
  final FavouritesStore favourites;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  /// OMDb answers "Too many results" for very short searches.
  static const _minQueryLength = 3;

  final _controller = TextEditingController();
  Timer? _debounce;
  MediaType _type = MediaType.all;

  List<MovieSummary> _results = [];
  int _totalResults = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  /// Increases with every new search, so a slow old response can't
  /// overwrite the results of a newer one.
  int _requestId = 0;

  String get _query => _controller.text.trim();
  bool get _hasMore => _results.length < _totalResults;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Waits until the user stops typing for half a second before searching,
  /// so we don't send a request for every key press.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _search);
    setState(() {}); // shows or hides the clear button
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    final query = _query;

    if (query.length < _minQueryLength) {
      setState(() {
        _results = [];
        _totalResults = 0;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.service.search(query, type: _type);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = page.movies;
        _totalResults = page.totalResults;
        _page = 1;
      });
    } on OmdbException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.message;
        _results = [];
        _totalResults = 0;
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.service.search(
        _query,
        type: _type,
        page: _page + 1,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = [..._results, ...next.movies];
        _page++;
      });
    } on OmdbException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openDetails(MovieSummary movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          movie: movie,
          service: widget.service,
          favourites: widget.favourites,
          heroTag: 'search-${movie.imdbId}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Finder')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search films and series…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              _search();
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SegmentedButton<MediaType>(
                segments: const [
                  ButtonSegment(value: MediaType.all, label: Text('All')),
                  ButtonSegment(
                    value: MediaType.movie,
                    label: Text('Movies'),
                    icon: Icon(Icons.movie_outlined),
                  ),
                  ButtonSegment(
                    value: MediaType.series,
                    label: Text('Series'),
                    icon: Icon(Icons.tv),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                  _search();
                },
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return MessageView(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _search,
      );
    }
    if (_query.length < _minQueryLength) {
      return const MessageView(
        icon: Icons.local_movies_outlined,
        title: 'Find your next film',
        message:
            'Type at least 3 letters to search over a million '
            'films and series.',
      );
    }
    if (_results.isEmpty) {
      return MessageView(
        icon: Icons.search_off,
        title: 'No results',
        message: 'We couldn\'t find anything matching "$_query".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _results.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index == _results.length) return _buildFooter();
        final movie = _results[index];
        return MovieTile(
          movie: movie,
          favourites: widget.favourites,
          heroTag: 'search-${movie.imdbId}',
          onTap: () => _openDetails(movie),
        );
      },
    );
  }

  Widget _buildFooter() {
    final summary = Text(
      'Showing ${_results.length} of $_totalResults results',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          if (_hasMore) ...[
            _loadingMore
                ? const CircularProgressIndicator()
                : FilledButton.tonal(
                    onPressed: _loadMore,
                    child: const Text('Load more'),
                  ),
            const SizedBox(height: 12),
          ],
          summary,
        ],
      ),
    );
  }
}
