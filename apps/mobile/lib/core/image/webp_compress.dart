import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressException implements Exception {
  const ImageCompressException([this.message = 'Gagal mengompres gambar.']);

  final String message;

  @override
  String toString() => message;
}

class ImageTooLargeException extends ImageCompressException {
  const ImageTooLargeException()
    : super('Gambar tetap > 80 KB setelah kompresi maksimal.');
}

/// Kompresi client-side ke WebP ≤ 80 KB (PRD X6, tech.md §3.6).
Future<Uint8List> compressToWebp(
  String path, {
  int maxBytes = 80 * 1024,
}) async {
  var quality = 80;
  var side = 1280;

  while (true) {
    final output = await FlutterImageCompress.compressWithFile(
      path,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: side,
      minHeight: side,
      keepExif: false,
    );
    if (output == null) throw const ImageCompressException();
    if (output.length <= maxBytes) return output;
    if (quality > 40) {
      quality -= 10;
    } else if (side > 640) {
      side = (side * 0.8).round();
      quality = 60;
    } else {
      throw const ImageTooLargeException();
    }
  }
}

/// Varian byte untuk hasil kamera yang sudah berada di memori.
Future<Uint8List> compressBytesToWebp(
  Uint8List input, {
  int maxBytes = 80 * 1024,
}) async {
  var quality = 80;
  var side = 1280;

  while (true) {
    final output = await FlutterImageCompress.compressWithList(
      input,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: side,
      minHeight: side,
      keepExif: false,
    );
    if (output.length <= maxBytes) return output;
    if (quality > 40) {
      quality -= 10;
    } else if (side > 640) {
      side = (side * 0.8).round();
      quality = 60;
    } else {
      throw const ImageTooLargeException();
    }
  }
}
