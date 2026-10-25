import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

/// An error with a message that is safe to show to the user.
class OmdbException implements Exception {
  const OmdbException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One page of search results (OMDb returns 10 per page).
class SearchPage {
  const SearchPage({required this.movies, required this.totalResults});

  final List<MovieSummary> movies;
  final int totalResults;
}

enum MediaType { all, movie, series }

/// Talks to the Open Movie Database API (https://www.omdbapi.com).
///
/// The HTTP client can be swapped for a fake one in tests.
class OmdbService {
  OmdbService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _host = 'www.omdbapi.com';
  static const _timeout = Duration(seconds: 10);

  Future<SearchPage> search(
    String query, {
    MediaType type = MediaType.all,
    int page = 1,
  }) async {
    final params = {'s': query.trim(), 'page': '$page'};
    if (type != MediaType.all) params['type'] = type.name;

    final json = await _get(params);
    if (json['Response'] == 'False') {
      // "Not found" is a normal result, not an error.
      if (json['Error'] == 'Movie not found!' ||
          json['Error'] == 'Series not found!') {
        return const SearchPage(movies: [], totalResults: 0);
      }
      throw OmdbException(_friendlyMessage(json['Error'] as String?));
    }

    final movies = [
      for (final item in json['Search'] as List)
        MovieSummary.fromJson(item as Map<String, dynamic>),
    ];
    return SearchPage(
      movies: movies,
      totalResults: int.tryParse('${json['totalResults']}') ?? movies.length,
    );
  }

  Future<MovieDetails> details(String imdbId) async {
    final json = await _get({'i': imdbId, 'plot': 'full'});
    if (json['Response'] == 'False') {
      throw OmdbException(_friendlyMessage(json['Error'] as String?));
    }
    return MovieDetails.fromJson(json);
  }

  /// All episodes of one season of a TV series.
  Future<Season> season(String seriesId, int seasonNumber) async {
    final json = await _get({'i': seriesId, 'Season': '$seasonNumber'});
    if (json['Response'] == 'False') {
      throw OmdbException(_friendlyMessage(json['Error'] as String?));
    }
    return Season.fromJson(json);
  }

  Future<Map<String, dynamic>> _get(Map<String, String> params) async {
    if (apiKey.isEmpty) {
      throw const OmdbException(
        'No API key found. Start the app with '
        '--dart-define=OMDB_API_KEY=your_key',
      );
    }

    final uri = Uri.https(_host, '/', {...params, 'apikey': apiKey});
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 401) {
        throw const OmdbException(
          'The API key was rejected. Check that it has been activated.',
        );
      }
      if (response.statusCode != 200) {
        throw OmdbException(
          'The movie database returned an error (${response.statusCode}). '
          'Please try again.',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on OmdbException {
      rethrow;
    } on TimeoutException {
      throw const OmdbException(
        'The request took too long. Check your connection and try again.',
      );
    } catch (_) {
      throw const OmdbException(
        'Could not reach the movie database. Check your internet connection.',
      );
    }
  }

  String _friendlyMessage(String? error) => switch (error) {
    'Too many results.' => 'Too many results. Try a more specific title.',
    'Incorrect IMDb ID.' => 'Sorry, we could not find that title.',
    'Request limit reached!' =>
      'The daily search limit has been reached. Please try again tomorrow.',
    'Invalid API key!' =>
      'The API key was rejected. Check that it has been activated.',
    _ => error ?? 'Something went wrong. Please try again.',
  };
}
