import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';

class AuthSession extends Notifier<User?> {
  AuthSession({this.inactivityTimeout = const Duration(minutes: 15)});

  final Duration inactivityTimeout;
  Timer? _inactivityTimer;

  @override
  User? build() {
    ref.onDispose(() => _inactivityTimer?.cancel());
    return null;
  }

  /// Returns true and updates state on success; returns false and leaves
  /// state unchanged on a bad username or password.
  Future<bool> login(String username, String password) async {
    final user = await ref.read(userRepositoryProvider).findByUsername(username);
    if (user == null) return false;

    final passwordMatches =
        ref.read(passwordHasherProvider).verify(password, user.passwordHash);
    if (!passwordMatches) return false;

    state = user;
    recordActivity();
    return true;
  }

  void recordActivity() {
    if (state == null) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, logout);
  }

  void logout() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    state = null;
  }
}

final authSessionProvider = NotifierProvider<AuthSession, User?>(AuthSession.new);
import 'dart:async';
