import 'package:flutter/material.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'services/omdb_service.dart';
import 'state/favourites_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final favourites = FavouritesStore();
  await favourites.load();

  runApp(
    MovieFinderApp(
      service: OmdbService(apiKey: omdbApiKey),
      favourites: favourites,
    ),
  );
}

class MovieFinderApp extends StatelessWidget {
  const MovieFinderApp({
    super.key,
    required this.service,
    required this.favourites,
  });

  final OmdbService service;
  final FavouritesStore favourites;

  static const _brandColour = Color(0xFFF5C518);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _brandColour,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _brandColour,
        brightness: Brightness.dark,
      ),
      home: HomeScreen(service: service, favourites: favourites),
    );
  }
}
