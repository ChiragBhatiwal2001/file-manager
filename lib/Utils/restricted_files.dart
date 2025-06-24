import 'dart:io';
import 'package:path/path.dart' as p;

class FileFilterUtils {
  static bool isHidden(FileSystemEntity entity) {
    final name = p.basename(entity.path);
    return name.startsWith('.');
  }

  static bool isRestrictedPath(String path) {
    final lower = path.toLowerCase();

    const systemDirs = [
      '/proc',
      '/sys',
      '/dev',
      '/acct',
      '/cache',
      '/vendor',
    ];

    const unwantedPatterns = [
      '/whatsapp/media/.statuses',
      '/whatsapp/.shared',
      '/android/media/com.whatsapp/.statuses',
      '/android/media/com.instagram.android/cache',
      '/android/media/com.instagram.android/instagram_cache',
      '/android/media/com.facebook.orca/cache',
      '/android/media/com.snapchat.android/cache',
      '/tencent/microvideo',
      '/tencent/qqfile_recv',
      '/miui/gallery/cloud/.cache',
      '.webp'
    ];

    for (final restricted in systemDirs) {
      if (lower.contains(restricted)) return true;
    }

    for (final pattern in unwantedPatterns) {
      if (lower.contains(pattern)) return true;
    }

    return false;
  }

  static bool shouldHideEntity(FileSystemEntity entity, {bool showHidden = false}) {
    if (!showHidden && isHidden(entity)) return true;
    if (isRestrictedPath(entity.path)) return true;
    return false;
  }

  static List<FileSystemEntity> filterVisible(List<FileSystemEntity> entities, {bool showHidden = false}) {
    return entities.where((e) => !shouldHideEntity(e, showHidden: showHidden)).toList();
  }
}
