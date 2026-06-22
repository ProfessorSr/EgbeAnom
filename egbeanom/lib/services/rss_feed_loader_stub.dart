class RssArticle {
  const RssArticle({
    required this.source,
    required this.title,
    required this.summary,
    required this.url,
  });

  final String source;
  final String title;
  final String summary;
  final String url;
}

Future<List<RssArticle>> loadFragranceRssArticles() async => [];
