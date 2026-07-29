import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/locale_provider.dart';
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
  final _confirmPasswordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.setupAdminError);
      return;
    }

    if (password != confirm) {
      setState(() => _errorText = l10n.passwordMismatchError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final hash = ref.read(passwordHasherProvider).hash(password);
      await ref.read(userRepositoryProvider).createUser(
            username: username,
            passwordHash: hash,
            role: 'admin',
          );
      await ref.read(authSessionProvider.notifier).login(username, password);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = l10n.setupAdminError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Pharmacy Icon ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ──
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.setupAdminSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Setup Card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.setupAdminTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),

                        // Username
                        TextField(
                          key: const Key('setupAdminUsername'),
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.usernameLabel,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextField(
                          key: const Key('setupAdminPassword'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextField(
                          key: const Key('setupAdminConfirmPassword'),
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: l10n.confirmPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),

                        // Error
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _errorText != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dangerColor.withAlpha(15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.dangerColor.withAlpha(60),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppTheme.dangerColor, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorText!,
                                            style: const TextStyle(
                                              color: AppTheme.dangerColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),

                        // Submit button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            key: const Key('setupAdminSubmit'),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.createAccountButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Language Switcher ──
                TextButton.icon(
                  key: const Key('setupLanguageSwitcher'),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(
                    locale.languageCode == 'id'
                        ? '🇮🇩 Bahasa Indonesia'
                        : '🇬🇧 English',
                  ),
                  onPressed: () =>
                      ref.read(localeProvider.notifier).toggleLocale(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
