import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'auth_session.dart';

class SetupAdminScreen extends ConsumerStatefulWidget {
  const SetupAdminScreen({super.key});

  @override
  ConsumerState<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends ConsumerState<SetupAdminScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.setupAdminError);
      return;
    }

    try {
      final hash = ref.read(passwordHasherProvider).hash(password);
      await ref.read(userRepositoryProvider).createUser(
            username: username,
            passwordHash: hash,
            role: 'admin',
          );
      await ref.read(authSessionProvider.notifier).login(username, password);
    } catch (_) {
      setState(() => _errorText = l10n.setupAdminError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupAdminTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('setupAdminUsername'),
              controller: _usernameController,
              decoration: InputDecoration(labelText: l10n.usernameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('setupAdminPassword'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.passwordLabel),
            ),
            const SizedBox(height: 24),
            if (_errorText != null) ...[
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('setupAdminSubmit'),
                onPressed: _submit,
                child: Text(l10n.createAccountButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
