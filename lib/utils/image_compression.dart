import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionUtil {
  static Future<Uint8List> compressImage(File file,
      {int maxWidth = 1600,
      int maxHeight = 1600,
      int quality = 80,
      CompressFormat format = CompressFormat.jpeg}) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: format,
    );
    if (result == null) {
      return await file.readAsBytes();
    }
    return result;
  }

  static Future<File> compressImageToFile(File file,
      {String? targetPath,
      int maxWidth = 1600,
      int maxHeight = 1600,
      int quality = 80,
      CompressFormat format = CompressFormat.jpeg}) async {
    final path = targetPath ??
        file.path.replaceFirst(RegExp(r'\.[^.]+$'),
            format == CompressFormat.jpeg ? '_compressed.jpg' : '_compressed.png');
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: format,
    );
    if (result == null) {
      return file;
    }
    return File(result.path);
  }
}
