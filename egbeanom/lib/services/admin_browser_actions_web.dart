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
  final blob = html.Blob([
    base64Decode(base64Contents),
  ], mimeType);
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
  body > *:not(#egbeanom-print-root) { display: none !important; }
  #egbeanom-print-root {
    display: block !important;
    font-family: Arial, sans-serif;
    color: #111;
    margin: 24px;
  }
  #egbeanom-print-root pre {
    white-space: pre-wrap;
    font-size: 12px;
    line-height: 1.45;
  }
  .egbeanom-print-page,
  .egbeanom-page-break {
    break-after: page;
    page-break-after: always;
  }
  .egbeanom-print-page:last-child,
  .egbeanom-page-break:last-child {
    break-after: auto;
    page-break-after: auto;
  }
}
''';
  final root = html.DivElement()
    ..id = 'egbeanom-print-root'
    ..style.display = 'none'
    ..setInnerHtml(htmlContents, treeSanitizer: html.NodeTreeSanitizer.trusted);
  html.document.title = title;
  html.document.head?.append(style);
  html.document.body?.append(root);
  html.window.print();
  Future<void>.delayed(const Duration(seconds: 1), () {
    root.remove();
    style.remove();
  });
}
