import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageServiceProvider = Provider((ref) => ImageService());

class ImageService {
  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: 1080,
      minWidth: 1080,
      quality: 80,
    );
    return result;
  }
}
