import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/app_update_service.dart';
import 'package:pharmacy_inventory_platform/features/home/update_banner.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({AppUpdateInfo? info}) {
    return ProviderScope(
      overrides: [
        appUpdateCheckFutureProvider.overrideWith((ref) async => info),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: UpdateBanner(),
        ),
      ),
    );
  }

  group('UpdateBanner', () {
    testWidgets('renders nothing when there is no update available', (tester) async {
      const info = AppUpdateInfo(
        currentVersion: '1.3.5',
        latestVersion: '1.3.5',
        releaseUrl: '',
        releaseNotes: '',
        hasUpdate: false,
      );

      await tester.pumpWidget(buildTestWidget(info: info));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('updateBanner')), findsNothing);
    });

    testWidgets('renders banner with title and buttons when update is available',
        (tester) async {
      const info = AppUpdateInfo(
        currentVersion: '1.3.5',
        latestVersion: '1.4.0',
        releaseUrl: 'https://github.com/owner/repo/releases/tag/v1.4.0',
        releaseNotes: 'New features',
        hasUpdate: true,
      );

      await tester.pumpWidget(buildTestWidget(info: info));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('updateBanner')), findsOneWidget);
      expect(find.text('Update Available: v1.4.0'), findsOneWidget);
      expect(find.byKey(const Key('viewUpdateReleaseBtn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('dismissUpdateBannerBtn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('updateBanner')), findsNothing);
    });
  });
}
