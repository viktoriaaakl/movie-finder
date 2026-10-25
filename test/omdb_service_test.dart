import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movie_finder/services/omdb_service.dart';

/// Builds a service whose HTTP client returns [body] instead of calling OMDb.
OmdbService fakeService(
  Map<String, dynamic> body, {
  int status = 200,
  void Function(Uri url)? onRequest,
}) {
  return OmdbService(
    apiKey: 'test-key',
    client: MockClient((request) async {
      onRequest?.call(request.url);
      return http.Response(jsonEncode(body), status);
    }),
  );
}

void main() {
  group('search', () {
    test('parses results and the total count', () async {
      final service = fakeService({
        'Response': 'True',
        'totalResults': '42',
        'Search': [
          {
            'Title': 'Inception',
            'Year': '2010',
            'imdbID': 'tt1375666',
            'Type': 'movie',
            'Poster': 'https://example.com/inception.jpg',
          },
          {
            'Title': 'Inception: The Cobol Job',
            'Year': '2010',
            'imdbID': 'tt5295894',
            'Type': 'movie',
            'Poster': 'N/A',
          },
        ],
      });

      final page = await service.search('inception');

      expect(page.totalResults, 42);
      expect(page.movies, hasLength(2));
      expect(page.movies.first.title, 'Inception');
      expect(page.movies.first.typeLabel, 'Movie');
      expect(page.movies.last.posterUrl, isNull);
    });

    test('sends the query, page, type and API key', () async {
      late Uri sent;
      final service = fakeService({
        'Response': 'True',
        'totalResults': '0',
        'Search': [],
      }, onRequest: (url) => sent = url);

      await service.search('  matrix ', type: MediaType.series, page: 2);

      expect(sent.queryParameters, {
        's': 'matrix',
        'page': '2',
        'type': 'series',
        'apikey': 'test-key',
      });
    });

    test('returns an empty page when nothing is found', () async {
      final service = fakeService({
        'Response': 'False',
        'Error': 'Movie not found!',
      });

      final page = await service.search('zzzzzz');

      expect(page.movies, isEmpty);
      expect(page.totalResults, 0);
    });

    test('turns API errors into friendly messages', () async {
      final service = fakeService({
        'Response': 'False',
        'Error': 'Invalid API key!',
      }, status: 401);

      expect(
        () => service.search('matrix'),
        throwsA(
          isA<OmdbException>().having(
            (e) => e.message,
            'message',
            contains('API key'),
          ),
        ),
      );
    });

    test('fails clearly when no API key is configured', () async {
      final service = OmdbService(
        apiKey: '',
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(() => service.search('matrix'), throwsA(isA<OmdbException>()));
    });
  });

  group('details', () {
    test('parses ratings and genres and ignores N/A values', () async {
      final service = fakeService({
        'Response': 'True',
        'Title': 'Inception',
        'Year': '2010',
        'imdbID': 'tt1375666',
        'Type': 'movie',
        'Poster': 'N/A',
        'Genre': 'Action, Adventure, Sci-Fi',
        'Director': 'Christopher Nolan',
        'Awards': 'N/A',
        'Plot': 'A thief who steals corporate secrets through dreams.',
        'Ratings': [
          {'Source': 'Internet Movie Database', 'Value': '8.8/10'},
        ],
      });

      final details = await service.details('tt1375666');

      expect(details.summary.title, 'Inception');
      expect(details.genres, ['Action', 'Adventure', 'Sci-Fi']);
      expect(details.director, 'Christopher Nolan');
      expect(details.awards, isNull);
      expect(details.ratings.single.source, 'IMDb');
      expect(details.ratings.single.value, '8.8/10');
    });
  });

  group('episode guide', () {
    test('season parses episodes and works out the statistics', () async {
      late Uri sent;
      final service = fakeService({
        'Response': 'True',
        'Title': 'Breaking Bad',
        'Season': '1',
        'totalSeasons': '5',
        'Episodes': [
          {
            'Title': 'Pilot',
            'Released': '2008-01-20',
            'Episode': '1',
            'imdbRating': '9.0',
            'imdbID': 'tt0959621',
          },
          {
            'Title': "Cat's in the Bag...",
            'Released': '2008-01-27',
            'Episode': '2',
            'imdbRating': '8.6',
            'imdbID': 'tt1054724',
          },
          {
            'Title': 'Unreleased',
            'Released': 'N/A',
            'Episode': '3',
            'imdbRating': 'N/A',
            'imdbID': 'tt0000003',
          },
        ],
      }, onRequest: (url) => sent = url);

      final season = await service.season('tt0903747', 1);

      expect(sent.queryParameters['Season'], '1');
      expect(season.totalSeasons, 5);
      expect(season.episodes, hasLength(3));
      expect(season.episodes.last.rating, isNull);
      expect(season.averageRating, closeTo(8.8, 0.001));
      expect(season.bestEpisode!.title, 'Pilot');
      expect(season.worstEpisode!.number, 2);
    });

    test('only series have an episode guide', () async {
      final series = await fakeService({
        'Response': 'True',
        'Title': 'Breaking Bad',
        'imdbID': 'tt0903747',
        'Type': 'series',
        'totalSeasons': '5',
      }).details('tt0903747');
      final film = await fakeService({
        'Response': 'True',
        'Title': 'Inception',
        'imdbID': 'tt1375666',
        'Type': 'movie',
      }).details('tt1375666');

      expect(series.hasEpisodeGuide, isTrue);
      expect(series.totalSeasons, 5);
      expect(film.hasEpisodeGuide, isFalse);
    });
  });
}
