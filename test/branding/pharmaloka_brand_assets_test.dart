import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String path) => File(path).readAsBytesSync();

({int width, int height}) _pngSize(String path) {
  final bytes = _bytes(path);
  expect(
      bytes.sublist(0, 8),
      [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ],
      reason: '$path must be a PNG');
  final data = ByteData.sublistView(bytes);
  return (
    width: data.getUint32(16, Endian.big),
    height: data.getUint32(20, Endian.big),
  );
}

Set<int> _icoSizes(String path) {
  final bytes = _bytes(path);
  final data = ByteData.sublistView(bytes);
  expect(data.getUint16(0, Endian.little), 0);
  expect(data.getUint16(2, Endian.little), 1);
  final count = data.getUint16(4, Endian.little);
  return {
    for (var index = 0; index < count; index++)
      bytes[6 + index * 16] == 0 ? 256 : bytes[6 + index * 16],
  };
}

String _text(String path) => File(path).readAsStringSync();

void main() {
  test('canonical SVG implements approved PharmaLoka Loka Bloom', () {
    final svg = _text('assets/branding/app_icon.svg');

    expect(svg, contains('viewBox="0 0 1024 1024"'));
    expect(svg, contains('#081A33'));
    expect(svg, contains('#123C69'));
    expect(svg, contains('#2DD4BF'));
    expect(svg, contains('#38BDF8'));
    expect(svg, contains('#22C55E'));
    expect(svg, contains('#16A34A'));
    expect(svg, isNot(contains('<text')));
    expect(svg, isNot(contains('<filter')));
  });

  test('generated brand assets have required platform sizes', () {
    const pngs = {
      'assets/branding/app_icon.png': 1024,
      'assets/branding/app_icon_source.png': 1024,
      'assets/branding/play_store_icon.png': 512,
      'web/favicon.png': 32,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'docs_site/assets/images/favicon.png': 32,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };

    for (final MapEntry(key: path, value: size) in pngs.entries) {
      expect(_pngSize(path), (width: size, height: size), reason: path);
    }
    expect(
      _icoSizes('windows/runner/resources/app_icon.ico'),
      containsAll({16, 24, 32, 48, 64, 128, 256}),
    );
  });

  test('adaptive Android and web resources use PharmaLoka branding', () {
    final manifest = _text('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('android:label="PharmaLoka"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));

    for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
      final adaptive = _text(
        'android/app/src/main/res/mipmap-anydpi-v26/$name',
      );
      expect(adaptive, contains('@color/ic_launcher_background'));
      expect(adaptive, contains('@drawable/ic_launcher_foreground'));
    }

    final webManifest =
        jsonDecode(_text('web/manifest.json')) as Map<String, dynamic>;
    expect(webManifest['name'], 'PharmaLoka — Pharmacy Inventory Platform');
    expect(webManifest['short_name'], 'PharmaLoka');
  });

  test('display surfaces use PharmaLoka and ProgrammerNewbie Studio', () {
    final expectedProductFiles = [
      'pubspec.yaml',
      'lib/main.dart',
      'lib/l10n/app_en.arb',
      'lib/l10n/app_id.arb',
      'lib/data/excel_report_service.dart',
      'android/app/src/main/AndroidManifest.xml',
      'windows/runner/main.cpp',
      'windows/runner/Runner.rc',
      'web/manifest.json',
      'web/index.html',
      'docs_site/_config.yml',
      'docs_site/_layouts/default.html',
      'docs_site/index.md',
      'README.md',
      'USER_GUIDE.md',
      'docs/INSTALLATION.md',
    ];
    for (final path in expectedProductFiles) {
      expect(_text(path), contains('PharmaLoka'), reason: path);
    }

    expect(_text('pubspec.yaml'), contains('ProgrammerNewbie Studio'));
    expect(
      _text('windows/runner/Runner.rc'),
      contains('ProgrammerNewbie Studio'),
    );
    expect(
      _text('docs_site/_layouts/default.html'),
      contains('ProgrammerNewbie Studio'),
    );

    const fullTitle = 'PharmaLoka — Pharmacy Inventory Platform';
    for (final path in [
      'lib/main.dart',
      'lib/data/excel_report_service.dart',
      'web/manifest.json',
      'web/index.html',
      'docs_site/_config.yml',
      'docs_site/_layouts/default.html',
      'README.md',
      'USER_GUIDE.md',
      'docs/INSTALLATION.md',
    ]) {
      expect(_text(path), contains(fullTitle), reason: path);
    }
    expect(
      _text('android/app/src/main/AndroidManifest.xml'),
      contains('android:label="PharmaLoka"'),
    );
    expect(
      jsonDecode(_text('web/manifest.json'))['short_name'],
      'PharmaLoka',
    );
  });

  test('technical identities stay upgrade compatible', () {
    expect(
      _text('pubspec.yaml'),
      contains('name: pharmacy_inventory_platform'),
    );
    expect(
      _text('pubspec.yaml'),
      contains('identity_name: com.programmernewbiecode.pharmacyinventory'),
    );
    expect(
      _text('android/app/build.gradle'),
      contains(
        'applicationId "com.programmernewbiecode.pharmaloka"',
      ),
    );
    expect(
      _text('windows/CMakeLists.txt'),
      contains('set(BINARY_NAME "pharmacy_inventory_platform")'),
    );
    expect(
      _text('windows/runner/Runner.rc'),
      contains('VALUE "OriginalFilename", "pharmacy_inventory_platform.exe"'),
    );
  });
}
