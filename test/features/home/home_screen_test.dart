import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/home/home_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

/// Shell tests target [PharmacyShell], the shell users actually get.
/// [HomeScreen] no longer builds chrome of its own, so asserting against it
/// directly would test a surface that does not exist in production.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void sizeTo(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> login(String username, String role) async {
    final hash = container.read(passwordHasherProvider).hash('secret123');
    await container.read(userRepositoryProvider).createUser(
          username: username,
          passwordHash: hash,
          role: role,
        );
    await container
        .read(authSessionProvider.notifier)
        .login(username, 'secret123');
  }

  /// login() arms a 15-minute inactivity Timer. The framework asserts no timer
  /// is pending at the end of the *test body*, before tearDowns run, so a
  /// tearDown cannot satisfy it. Tests that log in without signing out through
  /// the UI must call this before finishing.
  void endSession() => container.read(authSessionProvider.notifier).logout();

  Future<void> pumpShell(
    WidgetTester tester, {
    String locale = 'en',
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: textScale == 1.0
              ? null
              : (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(textScale)),
                    child: child!,
                  ),
          home: const PharmacyShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('chrome selection by width', () {
    testWidgets('1366x768 renders the sidebar and no bottom bar',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester);

      expect(find.byKey(const Key('desktopSidebar')), findsOneWidget);
      expect(find.byKey(const Key('mobileShellNavigation')), findsNothing);
    });

    testWidgets('1920x1080 renders the sidebar without overflow',
        (tester) async {
      sizeTo(tester, const Size(1920, 1080));
      makeContainer();
      await pumpShell(tester);

      expect(find.byKey(const Key('desktopSidebar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390x844 renders the bottom bar and no sidebar',
        (tester) async {
      sizeTo(tester, const Size(390, 844));
      makeContainer();
      await pumpShell(tester);

      expect(find.byKey(const Key('mobileShellNavigation')), findsOneWidget);
      expect(find.byKey(const Key('desktopSidebar')), findsNothing);
    });

    testWidgets('the sidebar boundary is exactly 1024px', (tester) async {
      sizeTo(tester, const Size(1023, 768));
      makeContainer();
      await pumpShell(tester);
      expect(find.byKey(const Key('desktopSidebar')), findsNothing);
      expect(find.byKey(const Key('mobileShellNavigation')), findsOneWidget);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desktopSidebar')), findsOneWidget);
      expect(find.byKey(const Key('mobileShellNavigation')), findsNothing);
    });

    testWidgets('tablet portrait deliberately uses the bottom bar, not a rail',
        (tester) async {
      // Documented decision, not an oversight: there is no evidence of tablet
      // use, so no third chrome tier exists. See
      // docs/superpowers/specs/2026-08-12-adaptive-shell-correctness.md.
      sizeTo(tester, const Size(768, 1024));
      makeContainer();
      await pumpShell(tester);

      expect(find.byKey(const Key('mobileShellNavigation')), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const Key('desktopSidebar')), findsNothing);
    });
  });

  group('global actions are reachable', () {
    testWidgets('sidebar exposes logout, language, and help', (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('budi', 'kasir');
      await pumpShell(tester);

      expect(find.byKey(const Key('logoutButton')), findsOneWidget);
      expect(find.byKey(const Key('languageToggle')), findsOneWidget);
      expect(find.byKey(const Key('helpButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('logoutButton')));
      await tester.pump();
      expect(container.read(authSessionProvider), isNull);
    });

    testWidgets('more sheet exposes logout below the sidebar breakpoint',
        (tester) async {
      sizeTo(tester, const Size(390, 844));
      makeContainer();
      await login('budi', 'kasir');
      await pumpShell(tester);

      // Not on the bottom bar itself; it lives behind More.
      expect(find.byKey(const Key('logoutButton')), findsNothing);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('logoutButton')), findsOneWidget);
      expect(find.byKey(const Key('languageToggle')), findsOneWidget);
      expect(find.byKey(const Key('helpButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();
      expect(container.read(authSessionProvider), isNull);
    });

    testWidgets('branding is admin-only in the sidebar', (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('owner', 'admin');
      await pumpShell(tester);
      expect(find.byKey(const Key('brandingButton')), findsOneWidget);
      endSession();
    });

    testWidgets('branding is hidden from a cashier in the sidebar',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('budi', 'kasir');
      await pumpShell(tester);
      expect(find.byKey(const Key('brandingButton')), findsNothing);
      endSession();
    });
  });

  group('navigation', () {
    testWidgets('sidebar dashboard item returns to the dashboard',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester);

      await tester.tap(find.byKey(const Key('desktopNavPos')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('navPosBtn')), findsNothing);

      await tester.tap(find.byKey(const Key('desktopNavDashboard')));
      await tester.pumpAndSettle();
      // The dashboard's own nav-cards prove we are back on the dashboard.
      expect(find.byKey(const Key('navPosBtn')), findsOneWidget);
    });

    testWidgets('a dashboard nav-card keeps the sidebar visible',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester);

      await tester.tap(find.byKey(const Key('navPosBtn')));
      await tester.pumpAndSettle();

      // Previously this pushed a route that covered the shell.
      expect(find.byKey(const Key('desktopSidebar')), findsOneWidget);
    });

    testWidgets('a destination opened from More reports More as selected',
        (tester) async {
      sizeTo(tester, const Size(390, 844));
      makeContainer();
      await pumpShell(tester);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moreNav_alerts')));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(
        find.byKey(const Key('mobileShellNavigation')),
      );
      // Previously this fell through to 0 and falsely highlighted Dashboard.
      expect(bar.selectedIndex, isNot(0));
      expect(bar.selectedIndex, bar.destinations.length - 1);
    });

    testWidgets('selecting a bottom-bar destination updates the selection',
        (tester) async {
      sizeTo(tester, const Size(390, 844));
      makeContainer();
      await pumpShell(tester);

      await tester.tap(find.byIcon(Icons.point_of_sale_outlined));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(
        find.byKey(const Key('mobileShellNavigation')),
      );
      expect(bar.selectedIndex, 1);
    });
  });

  group('permissions', () {
    testWidgets('admin sees user and backup destinations', (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('owner', 'admin');
      await pumpShell(tester);

      expect(find.byKey(const Key('desktopNavUsers')), findsOneWidget);
      expect(find.byKey(const Key('desktopNavBackup')), findsOneWidget);
      endSession();
    });

    testWidgets('cashier does not see user or backup destinations',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('budi', 'kasir');
      await pumpShell(tester);

      expect(find.byKey(const Key('desktopNavUsers')), findsNothing);
      expect(find.byKey(const Key('desktopNavBackup')), findsNothing);
      endSession();
    });
  });

  group('localization and accessibility', () {
    testWidgets('renders localized Indonesian shell strings', (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester, locale: 'id');

      expect(find.text('PharmaLoka'), findsWidgets);
      expect(find.text('Didukung oleh Programmer Newbie'), findsOneWidget);
    });

    testWidgets('branding nav-card subtitle comes from ARB, not hard-coded',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await login('owner', 'admin');
      await pumpShell(tester);

      // The English build must not show the previously hard-coded Indonesian.
      expect(find.text('Identitas & Header Struk'), findsNothing);
      expect(find.text('Identity & receipt header'), findsOneWidget);
      endSession();
    });

    testWidgets('sidebar destinations are labelled and touch-sized',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester);

      final inventory = find.byKey(const Key('desktopNavInventory'));
      expect(tester.getSemantics(inventory).label, 'Inventory Catalog');
      expect(tester.getSize(inventory).height, greaterThanOrEqualTo(48));
    });

    testWidgets('Tab traversal moves focus through sidebar destinations',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester);

      // Assert on focus itself rather than on a specific widget's internals:
      // the sidebar items are ListTiles wrapped by Material's own focus
      // machinery, so the reliable signal is that Tab produces a sequence of
      // distinct focused nodes and that InkWell focus reaches the nav items.
      final focusedLabels = <String>[];
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final node = primaryFocus;
        if (node == null) continue;
        final context = node.context;
        if (context == null) continue;
        // Walk up from the focused node to find an enclosing nav ListTile.
        String? label;
        context.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is ListTile) {
            final title = widget.title;
            if (title is Text && title.data != null) label = title.data;
            return false;
          }
          return true;
        });
        if (label != null && !focusedLabels.contains(label)) {
          focusedLabels.add(label!);
        }
      }

      expect(
        focusedLabels,
        containsAllInOrder(<String>['POS Register', 'Inventory Catalog']),
        reason: 'Tab must move focus through sidebar destinations in visual '
            'order; focused=$focusedLabels',
      );
    });

    testWidgets('shell survives 2.0 text scale without overflow',
        (tester) async {
      sizeTo(tester, const Size(1366, 768));
      makeContainer();
      await pumpShell(tester, textScale: 2.0);

      expect(tester.takeException(), isNull);
    });
  });
}
