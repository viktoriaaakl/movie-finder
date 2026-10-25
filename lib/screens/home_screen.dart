import 'package:flutter/material.dart';

import '../services/omdb_service.dart';
import '../state/favourites_store.dart';
import 'favourites_screen.dart';
import 'search_screen.dart';

/// The main layout with a bottom navigation bar for Search and Favourites.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.service,
    required this.favourites,
  });

  final OmdbService service;
  final FavouritesStore favourites;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps the search results when switching tabs.
      body: IndexedStack(
        index: _tab,
        children: [
          SearchScreen(service: widget.service, favourites: widget.favourites),
          FavouritesScreen(
            service: widget.service,
            favourites: widget.favourites,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.favourites,
        builder: (context, _) {
          final count = widget.favourites.items.length;
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.favorite_border),
                ),
                selectedIcon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.favorite),
                ),
                label: 'Favourites',
              ),
            ],
          );
        },
      ),
    );
  }
}
