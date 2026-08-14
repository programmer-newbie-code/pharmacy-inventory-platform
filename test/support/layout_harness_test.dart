import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_harness.dart';

/// Self-tests for the layout harness.
///
/// Required by docs/superpowers/plans/2026-08-13-narrow-screen-readability.md:
/// a harness that cannot detect a deliberate overflow would make every later
/// green result meaningless, so prove it fails when it should.
void main() {
  group('expectNoOverflow', () {
    testWidgets('detects a deliberate horizontal overflow', (tester) async {
      useSurface(tester, kOwnerPhone);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            // 3 x 200 = 600px of fixed content in a 393px surface.
            body: Row(
              children: [
                SizedBox(width: 200, height: 20),
                SizedBox(width: 200, height: 20),
                SizedBox(width: 200, height: 20),
              ],
            ),
          ),
        ),
      );

      // The overflow must be reported. Consume it so the test can end cleanly.
      expect(tester.takeException(), isNotNull,
          reason: 'a 600px Row in a 393px surface must overflow; if this is '
              'null the harness cannot detect overflow at all');
    });

    testWidgets('passes when content fits', (tester) async {
      useSurface(tester, kOwnerPhone);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(width: 100, height: 20),
                SizedBox(width: 100, height: 20),
              ],
            ),
          ),
        ),
      );

      expectNoOverflow(tester);
    });
  });

  group('expectNotTruncated', () {
    testWidgets('detects a single-line label squeezed into a narrow slot',
        (tester) async {
      useSurface(tester, kOwnerPhone);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60,
              child: Text(
                'Satuan Dasar (mis. tablet, kapsul)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      // Ellipsised text throws nothing, so overflow detection alone would miss
      // this. That is exactly the defect class the owner reported.
      expectNoOverflow(tester);

      late Object? failure;
      try {
        expectNotTruncated(tester, find.byType(Text));
      } catch (error) {
        failure = error;
      }
      expect(failure, isNotNull,
          reason: 'a 34-character label in a 60px slot is truncated; the '
              'harness must report it');
    });

    testWidgets('passes when the label has room', (tester) async {
      useSurface(tester, kOwnerPhone);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              child: Text('Satuan Dasar', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      );

      expectNotTruncated(tester, find.byType(Text));
    });

    testWidgets('honours a text scale override', (tester) async {
      useSurface(tester, kOwnerPhone);

      await tester.pumpWidget(
        MaterialApp(
          builder: textScaleBuilder(2.0),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              child: Text('Satuan Dasar', overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      );

      // At 2.0 scale this no longer fits in 120px, proving the harness reads
      // the MediaQuery override rather than the platform value.
      late Object? failure;
      try {
        expectNotTruncated(tester, find.byType(Text));
      } catch (error) {
        failure = error;
      }
      expect(failure, isNotNull,
          reason: 'text scale 2.0 must be taken into account');
    });
  });
}
