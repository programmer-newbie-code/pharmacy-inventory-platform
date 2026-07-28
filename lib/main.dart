import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'core/providers.dart';
import 'features/auth/auth_session.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/setup_admin_screen.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: PharmacyInventoryApp()));
}

class PharmacyInventoryApp extends StatelessWidget {
  const PharmacyInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Inventory Platform',
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const AuthGate(),
    );
  }
}

/// Decides between first-run setup, login, and the logged-in app based on
/// whether any user exists yet and whether one is currently logged in.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authSessionProvider);
    if (currentUser != null) return const HomeScreen();

    final userCount = ref.watch(_userCountProvider);
    return userCount.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
      data: (count) => count == 0 ? const SetupAdminScreen() : const LoginScreen(),
    );
  }
}

final _userCountProvider = FutureProvider<int>(
  (ref) => ref.watch(userRepositoryProvider).countUsers(),
);
