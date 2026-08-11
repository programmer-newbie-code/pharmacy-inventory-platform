import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  MediaStorageService({this.rootDirectoryOverride});

  final Directory? rootDirectoryOverride;

  Future<String> saveImage(String sourcePath, {required String folder}) async {
    final root = rootDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'PharmaLoka', 'Images', folder));
    await directory.create(recursive: true);
    final extension = p.extension(sourcePath);
    final target = File(p.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    ));
    await File(sourcePath).copy(target.path);
    return target.path;
  }
}
