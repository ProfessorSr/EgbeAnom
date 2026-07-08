// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

void downloadTextFile({
  required String fileName,
  required String contents,
  required String mimeType,
}) {
  final blob = html.Blob([contents], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void downloadBase64File({
  required String fileName,
  required String base64Contents,
  required String mimeType,
}) {
  final blob = html.Blob([base64Decode(base64Contents)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void printTextDocument(String title, String contents) {
  final escapedTitle = htmlEscape.convert(title);
  final escapedContents = htmlEscape.convert(contents);
  printHtmlDocument(title, '''
    <h1>$escapedTitle</h1>
    <pre>$escapedContents</pre>
''');
}

void printHtmlDocument(String title, String htmlContents) {
  final style = html.StyleElement()
    ..text = '''
@media print {
  @page { size: letter; margin: 0; }
  html, body {
    width: 8.5in;
    min-height: 11in;
    margin: 0 !important;
    padding: 0 !important;
    background: #fff !important;
  }
  body > *:not(#egbeanom-print-root) { display: none !important; }
  #egbeanom-print-root {
    display: block !important;
    position: static !important;
    width: 8.5in !important;
    font-family: Arial, sans-serif;
    color: #111;
    margin: 0 !important;
    padding: 0 !important;
  }
  #egbeanom-print-root pre {
    white-space: pre-wrap;
    font-size: 12px;
    line-height: 1.45;
  }
  .egbeanom-print-page {
    display: block !important;
    width: 8.5in !important;
    height: 11in !important;
    box-sizing: border-box !important;
    overflow: hidden !important;
    margin: 0 !important;
    break-after: page;
    page-break-after: always;
  }
  .egbeanom-print-page:last-child {
    break-after: auto;
    page-break-after: auto;
  }
  .egbeanom-page-break {
    display: none !important;
  }
}
''';
  final root = html.DivElement()
    ..id = 'egbeanom-print-root'
    ..style.display = 'none'
    ..style.width = '8.5in'
    ..setInnerHtml(htmlContents, treeSanitizer: html.NodeTreeSanitizer.trusted);
  html.document.title = title;
  html.document.head?.append(style);
  html.document.body?.append(root);
  unawaited(_printAfterImagesLoad(root, style));
}

Future<void> _printAfterImagesLoad(
  html.DivElement root,
  html.StyleElement style,
) async {
  final images = root.querySelectorAll('img').whereType<html.ImageElement>();
  await Future.wait([
    for (final image in images)
      if (image.complete != true)
        Future.any<void>([
          image.onLoad.first.then((_) {}),
          image.onError.first.then((_) {}),
          Future<void>.delayed(const Duration(seconds: 2)),
        ]),
  ]);
  html.window.print();
  unawaited(_cleanupAfterPrint(root, style));
}

Future<void> _cleanupAfterPrint(
  html.DivElement root,
  html.StyleElement style,
) async {
  await Future<void>.delayed(const Duration(minutes: 5));
  root.remove();
  style.remove();
}
