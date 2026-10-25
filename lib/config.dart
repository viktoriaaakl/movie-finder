/// The OMDb API key is passed in when the app is started, so it is never
/// stored in the code or committed to Git:
///
///   flutter run -d chrome --dart-define=OMDB_API_KEY=your_key
const String omdbApiKey = String.fromEnvironment('OMDB_API_KEY');
