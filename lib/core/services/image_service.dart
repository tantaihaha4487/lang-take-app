import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageServiceProvider = Provider((ref) => ImageService());

class ImageService {
  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    // flutter_image_compress relies on native mobile libraries and may not support Linux.
    // Return original bytes on Linux or Web to avoid UnimplementedError.
    if (Platform.isLinux || kIsWeb) {
      return imageBytes;
    }

    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 1080,
        minWidth: 1080,
        quality: 80,
      );
      return result;
    } catch (e) {
      // Fallback to original image if compression fails
      return imageBytes;
    }
  }
}
