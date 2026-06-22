// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

const _rssRequestTimeout = Duration(milliseconds: 3500);

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

Future<List<RssArticle>> loadFragranceRssArticles() async {
  final feeds = const [
    ('Basenotes', 'https://basenotes.com/feed/'),
    ('ÇaFleureBon', 'https://cafleurebon.com/feed/'),
    (
      'Premium Beauty News',
      'https://www.premiumbeautynews.com/spip.php?page=backend',
    ),
  ];
  final articles = <RssArticle>[];
  for (final feed in feeds) {
    try {
      var response = await _requestFeed(feed.$2);
      if ((response.responseText ?? '').trim().isEmpty) {
        response = await _requestFeed(_proxyUrl(feed.$2));
      }
      articles.addAll(_parseFeed(feed.$1, response.responseText ?? ''));
    } catch (_) {
      try {
        final response = await _requestFeed(_proxyUrl(feed.$2));
        articles.addAll(_parseFeed(feed.$1, response.responseText ?? ''));
      } catch (_) {
        // Browser CORS can block RSS feeds; the app keeps existing articles.
      }
    }
  }
  return articles.take(9).toList();
}

Future<html.HttpRequest> _requestFeed(String url) =>
    html.HttpRequest.request(url).timeout(_rssRequestTimeout);

String _proxyUrl(String url) =>
    'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';

List<RssArticle> _parseFeed(String source, String xml) {
  final matches = RegExp(
    r'<item[\s\S]*?</item>|<entry[\s\S]*?</entry>',
    caseSensitive: false,
  ).allMatches(xml);
  return [
    for (final match in matches)
      RssArticle(
        source: source,
        title: _clean(_tag(match.group(0) ?? '', 'title')),
        summary: _clean(
          _tag(match.group(0) ?? '', 'description').isEmpty
              ? _tag(match.group(0) ?? '', 'summary')
              : _tag(match.group(0) ?? '', 'description'),
        ),
        url: _clean(
          _tag(match.group(0) ?? '', 'link').isEmpty
              ? _attr(match.group(0) ?? '', 'link', 'href')
              : _tag(match.group(0) ?? '', 'link'),
        ),
      ),
  ].where((article) => article.title.isNotEmpty).toList();
}

String _tag(String xml, String tag) {
  final match = RegExp(
    '<$tag[^>]*>([\\s\\S]*?)</$tag>',
    caseSensitive: false,
  ).firstMatch(xml);
  return match?.group(1) ?? '';
}

String _attr(String xml, String tag, String attr) {
  final match = RegExp(
    '<$tag[^>]*$attr=["\\\']([^"\\\']+)["\\\'][^>]*>',
    caseSensitive: false,
  ).firstMatch(xml);
  return match?.group(1) ?? '';
}

String _clean(String value) {
  var cleaned = value
      .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&ndash;', '-')
      .replaceAll('&mdash;', '-')
      .replaceAll('&hellip;', '...')
      .replaceAll('&rsquo;', "'")
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rdquo;', '"')
      .replaceAll('&ldquo;', '"')
      .replaceAll('&#8217;', "'")
      .replaceAll('&#8216;', "'")
      .replaceAll('&#8220;', '"')
      .replaceAll('&#8221;', '"')
      .replaceAll('&#8211;', '-')
      .replaceAll('&#8212;', '-')
      .replaceAll('&#8230;', '...')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'&#([0-9]+);'),
    (match) => String.fromCharCode(int.parse(match.group(1)!)),
  );
  return cleaned;
}
