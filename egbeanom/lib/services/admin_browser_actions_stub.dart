void downloadTextFile({
  required String fileName,
  required String contents,
  required String mimeType,
}) {}

void downloadBase64File({
  required String fileName,
  required String base64Contents,
  required String mimeType,
}) {}

void printTextDocument(String title, String contents) {}

void printHtmlDocument(String title, String htmlContents) {}
