import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pdfx/pdfx.dart';

class ThumbnailService {
  static final _thumbnailCache = <String, Uint8List?>{};

  static Future<Uint8List?> getThumbnail(String path) async {
    if (_thumbnailCache.containsKey(path)) return _thumbnailCache[path];

    final ext = p.extension(path).toLowerCase();

    try {
      Uint8List? thumb;
      if (_isImage(ext)) {
        thumb = await File(path).readAsBytes();
      } else if (_isVideo(ext)) {
        thumb = await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 150,
          quality: 75,
        );
      } else if (ext == '.pdf') {
        thumb = await _generatePdfThumbnail(path);
      }

      _thumbnailCache[path] = thumb;
      return thumb;
    } catch (e) {
      debugPrint('Thumbnail error for $path: $e');
      return null;
    }
  }

  static bool _isImage(String ext) =>
      ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext);

  static bool _isVideo(String ext) =>
      ['.mp4', '.avi', '.mkv', '.mov', '.flv', '.3gp'].contains(ext);

  static Future<Uint8List?> _generatePdfThumbnail(String path) async {
    final doc = await PdfDocument.openFile(path);
    final page = await doc.getPage(1);
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.png,
    );
    await page.close();
    await doc.close();
    return pageImage?.bytes;
  }
}
