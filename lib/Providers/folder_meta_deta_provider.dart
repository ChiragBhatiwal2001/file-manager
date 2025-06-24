import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/get_meta_data.dart';

final folderMetadataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, path) async {
      return await getMetadata(path);
    });
