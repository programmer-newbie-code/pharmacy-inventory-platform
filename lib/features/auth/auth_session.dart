import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';

class AuthSession extends Notifier<User?> {
  @override
  User? build() => null;

  /// Returns true and updates state on success; returns false and leaves
  /// state unchanged on a bad username or password.
  Future<bool> login(String username, String password) async {
    final user = await ref.read(userRepositoryProvider).findByUsername(username);
    if (user == null) return false;

    final passwordMatches =
        ref.read(passwordHasherProvider).verify(password, user.passwordHash);
    if (!passwordMatches) return false;

    state = user;
    return true;
  }

  void logout() => state = null;
}

final authSessionProvider = NotifierProvider<AuthSession, User?>(AuthSession.new);
