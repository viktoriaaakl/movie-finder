/// A film or series as it appears in OMDb search results.
class MovieSummary {
  const MovieSummary({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.type,
    this.posterUrl,
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) => MovieSummary(
    imdbId: json['imdbID'] as String,
    title: json['Title'] as String? ?? 'Untitled',
    year: json['Year'] as String? ?? '',
    type: json['Type'] as String? ?? '',
    posterUrl: _posterOrNull(json['Poster']),
  );

  final String imdbId;
  final String title;
  final String year;
  final String type;

  /// Null when OMDb has no poster for this title.
  final String? posterUrl;

  /// "movie" -> "Movie", "series" -> "Series", etc.
  String get typeLabel =>
      type.isEmpty ? '' : type[0].toUpperCase() + type.substring(1);

  Map<String, dynamic> toJson() => {
    'imdbID': imdbId,
    'Title': title,
    'Year': year,
    'Type': type,
    'Poster': posterUrl ?? 'N/A',
  };
}

/// A single review score, e.g. IMDb 8.8/10 or Rotten Tomatoes 87%.
class Rating {
  const Rating({required this.source, required this.value});

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    source: _shortSourceName(json['Source'] as String? ?? ''),
    value: json['Value'] as String? ?? '',
  );

  final String source;
  final String value;
}

/// Full information about one title, from OMDb's "search by ID" endpoint.
class MovieDetails {
  const MovieDetails({
    required this.summary,
    this.rated,
    this.released,
    this.runtime,
    this.genre,
    this.director,
    this.writer,
    this.actors,
    this.plot,
    this.language,
    this.awards,
    this.totalSeasons,
    this.ratings = const [],
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) => MovieDetails(
    summary: MovieSummary.fromJson(json),
    rated: _valueOrNull(json['Rated']),
    released: _valueOrNull(json['Released']),
    runtime: _valueOrNull(json['Runtime']),
    genre: _valueOrNull(json['Genre']),
    director: _valueOrNull(json['Director']),
    writer: _valueOrNull(json['Writer']),
    actors: _valueOrNull(json['Actors']),
    plot: _valueOrNull(json['Plot']),
    language: _valueOrNull(json['Language']),
    awards: _valueOrNull(json['Awards']),
    totalSeasons: int.tryParse('${json['totalSeasons']}'),
    ratings: [
      for (final rating in (json['Ratings'] as List? ?? const []))
        Rating.fromJson(rating as Map<String, dynamic>),
    ],
  );

  final MovieSummary summary;
  final String? rated;
  final String? released;
  final String? runtime;
  final String? genre;
  final String? director;
  final String? writer;
  final String? actors;
  final String? plot;
  final String? language;
  final String? awards;

  /// Only set for TV series.
  final int? totalSeasons;
  final List<Rating> ratings;

  List<String> get genres => genre?.split(', ') ?? const [];

  bool get hasEpisodeGuide =>
      summary.type == 'series' && (totalSeasons ?? 0) > 0;
}

/// One episode in a season of a TV series.
class Episode {
  const Episode({
    required this.number,
    required this.title,
    required this.imdbId,
    this.released,
    this.rating,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    number: int.tryParse('${json['Episode']}') ?? 0,
    title: json['Title'] as String? ?? 'Untitled',
    imdbId: json['imdbID'] as String? ?? '',
    released: _valueOrNull(json['Released']),
    rating: double.tryParse('${json['imdbRating']}'),
  );

  final int number;
  final String title;
  final String imdbId;
  final String? released;

  /// IMDb rating out of 10, or null if the episode has no rating yet.
  final double? rating;
}

/// All episodes in one season, plus a few statistics.
class Season {
  const Season({
    required this.number,
    required this.totalSeasons,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) => Season(
    number: int.tryParse('${json['Season']}') ?? 1,
    totalSeasons: int.tryParse('${json['totalSeasons']}') ?? 1,
    episodes: [
      for (final episode in (json['Episodes'] as List? ?? const []))
        Episode.fromJson(episode as Map<String, dynamic>),
    ],
  );

  final int number;
  final int totalSeasons;
  final List<Episode> episodes;

  List<Episode> get rated => episodes.where((e) => e.rating != null).toList();

  /// Average IMDb rating of the rated episodes, or null if none are rated.
  double? get averageRating {
    final ratings = rated.map((e) => e.rating!).toList();
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Episode? get bestEpisode => rated.isEmpty
      ? null
      : rated.reduce((a, b) => b.rating! > a.rating! ? b : a);

  Episode? get worstEpisode => rated.isEmpty
      ? null
      : rated.reduce((a, b) => b.rating! < a.rating! ? b : a);
}

/// OMDb uses the text "N/A" for missing values; we turn that into null.
String? _valueOrNull(Object? value) =>
    value is String && value.isNotEmpty && value != 'N/A' ? value : null;

String? _posterOrNull(Object? value) =>
    value is String && value.startsWith('http') ? value : null;

String _shortSourceName(String source) => switch (source) {
  'Internet Movie Database' => 'IMDb',
  _ => source,
};
