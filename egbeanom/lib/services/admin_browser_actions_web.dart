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
  html.document.title = title;
  final documentHtml = _buildPrintDocument(title, htmlContents);
  final blob = html.Blob([documentHtml], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.window.open(url, '_blank', 'width=980,height=760');

  unawaited(
    Future<void>.delayed(const Duration(minutes: 3), () {
      html.Url.revokeObjectUrl(url);
    }),
  );
}

String _buildPrintDocument(String title, String htmlContents) {
  final safeTitle = htmlEscape.convert(title);
  final baseHref = html.window.location.origin;
  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <base href="$baseHref/">
    <title>$safeTitle</title>
    <style>
      @page { size: letter; margin: 0; }
      html, body {
        width: auto;
        min-height: auto;
        height: auto;
        margin: 0;
        padding: 0;
        background: #fff;
        overflow: visible;
      }
      body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
      #egbeanom-print-root {
        display: block;
        width: auto;
        max-width: none;
        font-family: Arial, sans-serif;
        color: #111;
        margin: 0;
        padding: 0;
        overflow: visible;
      }
      #egbeanom-print-root pre {
        white-space: pre-wrap;
        font-size: 12px;
        line-height: 1.45;
      }
      .egbeanom-print-page {
        display: block;
        width: 8.5in;
        height: 10.95in;
        box-sizing: border-box;
        overflow: hidden;
        margin: 0;
        break-inside: avoid;
        page-break-inside: avoid;
        break-after: page;
        page-break-after: always;
      }
      .egbeanom-print-page + .egbeanom-print-page {
        break-before: page;
        page-break-before: always;
      }
      .egbeanom-print-page:last-child {
        break-after: auto;
        page-break-after: auto;
      }
      .egbeanom-page-break {
        display: none;
      }
    </style>
    <script>
      (async function () {
        const images = Array.from(document.images || []);
        await Promise.all(images.map((img) => {
          if (img.complete) return Promise.resolve();
          return Promise.race([
            new Promise((resolve) => img.addEventListener('load', resolve, { once: true })),
            new Promise((resolve) => img.addEventListener('error', resolve, { once: true })),
            new Promise((resolve) => setTimeout(resolve, 2000)),
          ]);
        }));

        setTimeout(() => {
          window.focus();
          window.print();
          setTimeout(() => window.close(), 120000);
        }, 60);
      })();
    </script>
  </head>
  <body>
    <div id="egbeanom-print-root">$htmlContents</div>
  </body>
</html>
''';
}
