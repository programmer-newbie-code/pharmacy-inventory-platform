import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/media_storage_service.dart';

void main() {
  test('copies an image into the app media directory', () async {
    final root = await Directory.systemTemp.createTemp('media_storage_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.jpg');
    await source.writeAsBytes([1, 2, 3]);

    final savedPath = await MediaStorageService(rootDirectoryOverride: root)
        .saveImage(source.path, folder: 'products');

    expect(savedPath, contains('PharmaLoka'));
    expect(savedPath, contains('Images'));
    expect(savedPath, contains('products'));
    expect(savedPath, isNot(source.path));
    expect(await File(savedPath).readAsBytes(), [1, 2, 3]);
  });
}
