import 'package:flutter_test/flutter_test.dart';
import 'package:movie_finder/models/movie.dart';
import 'package:movie_finder/state/favourites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const movie = MovieSummary(
    imdbId: 'tt0133093',
    title: 'The Matrix',
    year: '1999',
    type: 'movie',
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('toggle adds and then removes a favourite', () async {
    final store = FavouritesStore();

    await store.toggle(movie);
    expect(store.contains(movie.imdbId), isTrue);

    await store.toggle(movie);
    expect(store.items, isEmpty);
  });

  test('favourites are saved and loaded again', () async {
    await FavouritesStore().toggle(movie);

    final reopened = FavouritesStore();
    await reopened.load();

    expect(reopened.items.single.title, 'The Matrix');
  });
}
