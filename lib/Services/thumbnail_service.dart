import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pdfx/pdfx.dart';

class ThumbnailService {
  static Future<Uint8List?> getSmartThumbnail(String path) async {
    final ext = p.extension(path).toLowerCase();

    try {
      if (_isImage(ext)) return await File(path).readAsBytes();
      if (_isVideo(ext)) {
        return await VideoThumbnail.thumbnailData(
          video: path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 150,
          quality: 75,
        );
      }
      if (ext == '.pdf') return await _generatePdfThumbnail(path);
    } catch (e) {
      debugPrint('Thumbnail error for $path: $e');
    }
    return null;
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
