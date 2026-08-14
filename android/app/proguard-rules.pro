# Baseline ProGuard/R8 rules for release builds.
#
# Modern Flutter plugin AARs bundle their own consumer ProGuard rules, which
# R8 merges automatically at build time. This file intentionally does not
# attempt to write keep rules for sqlite3_flutter_libs, mobile_scanner, or
# google_sign_in internals -- doing so without a device to verify against
# risks masking a real missing-rule crash instead of fixing it. See
# docs/superpowers/specs/2026-08-14-android-shrink-obfuscate.md.
#
# getDefaultProguardFile('proguard-android-optimize.txt'), referenced
# alongside this file in build.gradle, already supplies the standard
# Android/Flutter engine baseline. Add project-specific rules below only in
# response to a reproduced release-build crash, not speculatively.
