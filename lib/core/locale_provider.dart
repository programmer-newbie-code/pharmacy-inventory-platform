import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Provides runtime locale switching. Defaults to Indonesian.
/// The admin can toggle between 'id' and 'en' from the home screen.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('id');

  void setLocale(Locale locale) => state = locale;

  void toggleLocale() {
    state = state.languageCode == 'id'
        ? const Locale('en')
        : const Locale('id');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
