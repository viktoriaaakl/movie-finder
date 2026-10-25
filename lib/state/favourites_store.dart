import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

/// Keeps the user's favourite titles and saves them on the device,
/// so they are still there after the app is closed.
class FavouritesStore extends ChangeNotifier {
  static const _storageKey = 'favourites';

  final List<MovieSummary> _items = [];

  List<MovieSummary> get items => List.unmodifiable(_items);

  bool contains(String imdbId) => _items.any((m) => m.imdbId == imdbId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? const [];
    _items
      ..clear()
      ..addAll(
        saved.map(
          (s) => MovieSummary.fromJson(jsonDecode(s) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  Future<void> toggle(MovieSummary movie) async {
    if (contains(movie.imdbId)) {
      _items.removeWhere((m) => m.imdbId == movie.imdbId);
    } else {
      _items.insert(0, movie);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _items.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }
}
