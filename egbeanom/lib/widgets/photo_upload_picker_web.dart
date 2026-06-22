// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
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

Future<List<UploadedImageFile>> pickProductImages() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  input.click();

  await input.onChange.first;
  final files = input.files ?? const <html.File>[];
  final selected = <UploadedImageFile>[];
  for (final file in files) {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final result = reader.result;
    final bytes = result is ByteBuffer
        ? Uint8List.fromList(Uint8List.view(result))
        : Uint8List.fromList(result as List<int>);

    final dataReader = html.FileReader();
    dataReader.readAsDataUrl(file);
    await dataReader.onLoad.first;

    selected.add(
      UploadedImageFile(
        name: file.name,
        bytes: bytes,
        contentType: file.type.isEmpty ? 'image/jpeg' : file.type,
        dataUrl: dataReader.result as String,
      ),
    );
  }
  return selected;
}
