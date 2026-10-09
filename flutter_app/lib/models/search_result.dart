class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String category;
  final String engine;

  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.category,
    required this.engine,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      snippet: json['snippet'] ?? '',
      category: json['category'] ?? 'general',
      engine: json['engine'] ?? 'unknown',
    );
  }
}
