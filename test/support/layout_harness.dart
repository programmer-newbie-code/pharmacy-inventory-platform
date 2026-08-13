import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test-only helpers for catching layout problems at real device sizes.
///
/// Feature screens were previously only exercised at the default 800x600 test
/// surface, which is wider than any phone. That is why truncation on a ~393dp
/// device reached a release unnoticed. See
/// docs/superpowers/specs/2026-08-13-narrow-screen-readability.md.

/// The reporting owner's device: Vivo V23e, 1080x2400 at ~2.75 DPR.
const Size kOwnerPhone = Size(393, 873);

/// A common small-phone floor, to catch worse cases than the owner's device.
const Size kSmallPhone = Size(360, 640);

/// A desktop width, where paired layouts are expected to stay side by side.
const Size kDesktop = Size(1366, 768);

/// Sets the surface to [size] for one test and restores it afterwards.
void useSurface(WidgetTester tester, Size size, {double devicePixelRatio = 1}) {
  tester.view.physicalSize = size * devicePixelRatio;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// A `MaterialApp.builder` that applies [textScale] to everything below it.
///
/// Pass to `MaterialApp(builder: textScaleBuilder(2.0))`. It has to live inside
/// `MaterialApp` rather than wrapping it: above `MaterialApp` there is no
/// `MediaQuery` ancestor to copy from, so `MediaQuery.of` would throw.
TransitionBuilder textScaleBuilder(double textScale) {
  return (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      );
}

/// Fails if the most recent pump produced a layout overflow.
///
/// A `RenderFlex overflowed` error is reported as a test exception, so this
/// surfaces it with a clearer message than a bare `takeException` assertion.
/// Note that ellipsised text is **not** an exception: `Text` with
/// `overflow: ellipsis` lays out happily, so truncation must be asserted
/// separately via [expectNotTruncated].
void expectNoOverflow(WidgetTester tester, {String? reason}) {
  final error = tester.takeException();
  // FlutterError's toString() is one line; the full box-constraints
  // diagnostic that pinpoints the overflowing widget is only in
  // FlutterErrorDetails, which the default matcher does not surface. Print it
  // explicitly so a CI failure is diagnosable without another push+wait cycle.
  if (error is FlutterError) {
    debugPrint('--- expectNoOverflow FlutterError.toString() ---');
    debugPrint(error.toString());
    debugPrint('--- diagnostics ---');
    for (final line in error.diagnostics) {
      debugPrint(line.toString());
    }
    debugPrint('--- end ---');
  }
  expect(
    error,
    isNull,
    reason: reason ?? 'layout overflowed at this surface size: $error',
  );
}

/// Fails if the text found by [finder] was truncated or ellipsised as laid out.
///
/// **Only valid for plain `Text` widgets.** Do not point this at an
/// `InputDecoration` label: `find.text` there resolves to a `Text` whose nearest
/// `RenderParagraph` belongs to the decoration subtree, which reported an
/// identical slot width and a spurious truncation for both a 34-character and a
/// 12-character label. Use [expectNoOverflow] plus a presence assertion for
/// form-field labels instead.
///
/// Asks the `RenderParagraph` itself via `didExceedMaxLines`, which is
/// documented as "whether the text was truncated or ellipsized as laid out".
/// That is the real rendered outcome, so it needs no assumptions about font
/// size, ambient style, or text scale.
///
/// An earlier version rebuilt a `TextPainter` from the `Text` widget's style
/// and over-reported truncation, because a floating `InputDecoration` label is
/// painted with a different style than the widget declares. Measuring the
/// render object avoids guessing entirely.
void expectNotTruncated(
  WidgetTester tester,
  Finder finder, {
  String? reason,
}) {
  final element = tester.element(finder);
  RenderParagraph? paragraph;

  void visit(Element node) {
    if (paragraph != null) return;
    final renderObject = node.renderObject;
    if (renderObject is RenderParagraph) {
      paragraph = renderObject;
      return;
    }
    node.visitChildren(visit);
  }

  final self = element.renderObject;
  if (self is RenderParagraph) {
    paragraph = self;
  } else {
    element.visitChildren(visit);
  }

  expect(paragraph, isNotNull,
      reason: 'expectNotTruncated needs a text-rendering widget');
  expect(
    paragraph!.didExceedMaxLines,
    isFalse,
    reason: reason ??
        'text was truncated or ellipsised as laid out in '
            '${paragraph!.size.width}px',
  );
}
