import 'dart:typed_data';

class UploadedImageFile {
  const UploadedImageFile({
    required this.name,
    required this.bytes,
    required this.contentType,
    required this.dataUrl,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
  final String dataUrl;
}

Future<List<UploadedImageFile>> pickProductImages() async => [];
