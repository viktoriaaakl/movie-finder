import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movie_finder/main.dart';
import 'package:movie_finder/services/omdb_service.dart';
import 'package:movie_finder/state/favourites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('search for a film, open it and add it to favourites', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final client = MockClient((request) async {
      final isSearch = request.url.queryParameters.containsKey('s');
      final body = isSearch
          ? {
              'Response': 'True',
              'totalResults': '1',
              'Search': [
                {
                  'Title': 'Inception',
                  'Year': '2010',
                  'imdbID': 'tt1375666',
                  'Type': 'movie',
                  'Poster': 'N/A',
                },
              ],
            }
          : {
              'Response': 'True',
              'Title': 'Inception',
              'Year': '2010',
              'imdbID': 'tt1375666',
              'Type': 'movie',
              'Poster': 'N/A',
              'Director': 'Christopher Nolan',
              'Plot': 'A thief who steals corporate secrets through dreams.',
            };
      return http.Response(jsonEncode(body), 200);
    });

    await tester.pumpWidget(
      MovieFinderApp(
        service: OmdbService(apiKey: 'test-key', client: client),
        favourites: FavouritesStore(),
      ),
    );

    // Start screen.
    expect(find.text('Find your next film'), findsOneWidget);

    // Search (wait for the 500 ms debounce).
    await tester.enterText(find.byType(TextField), 'inception');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Inception'), findsOneWidget);

    // Open the details screen.
    await tester.tap(find.text('Inception'));
    await tester.pumpAndSettle();
    expect(find.text('Christopher Nolan'), findsOneWidget);

    // Add to favourites from the details screen.
    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pump();
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);
  });
}
