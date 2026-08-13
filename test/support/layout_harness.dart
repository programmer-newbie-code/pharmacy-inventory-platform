import 'package:flutter/material.dart';
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
  expect(
    error,
    isNull,
    reason: reason ?? 'layout overflowed at this surface size: $error',
  );
}

/// Fails if the `Text` found by [finder] is rendered narrower than the width it
/// needs, which is what produces a visible `...`.
///
/// Measures the text's intrinsic width with the same style and text scale, then
/// compares it against the width actually painted. A single-line `Text` that is
/// wider than its slot is truncated; allowing [tolerance] absorbs rounding.
void expectNotTruncated(
  WidgetTester tester,
  Finder finder, {
  double tolerance = 1.0,
  String? reason,
}) {
  final widget = tester.widget<Text>(finder);
  final data = widget.data;
  expect(data, isNotNull,
      reason: 'expectNotTruncated needs a Text with a plain string');

  final rendered = tester.getSize(finder);
  final maxLines = widget.maxLines ?? 1;

  // Read the scaler and the resolved style from the Text's own context, so an
  // enclosing MediaQuery override and the ambient DefaultTextStyle are both
  // honoured. Reading the platform value instead would ignore the override.
  final context = tester.element(finder);
  final scaler = MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;
  final style = DefaultTextStyle.of(context).style.merge(widget.style);

  final painter = TextPainter(
    text: TextSpan(text: data, style: style),
    textDirection: Directionality.of(context),
    textScaler: scaler,
    maxLines: maxLines,
  )..layout(maxWidth: rendered.width);

  expect(
    painter.didExceedMaxLines,
    isFalse,
    reason: reason ??
        'text "$data" is truncated: needs more than $maxLines line(s) '
            'in ${rendered.width}px',
  );
}
