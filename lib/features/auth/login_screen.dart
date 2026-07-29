import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import 'auth_session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _showError = false;
    });

    final success = await ref.read(authSessionProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _showError = !success;
    });

    if (!success) {
      _shakeController.forward(from: 0);
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
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = _shakeController.isAnimating
                    ? 8 *
                        (0.5 - _shakeController.value).abs() *
                        (_shakeController.value < 0.25 || _shakeController.value > 0.75
                            ? 1
                            : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Pharmacy Icon ──
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
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
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── Login Card ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.loginTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 20),

                          // Username
                          TextField(
                            key: const Key('loginUsername'),
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
                            key: const Key('loginPassword'),
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
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 8),

                          // Error message
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _showError
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
                                              l10n.loginError,
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

                          // Login button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('loginSubmit'),
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
                                  : Text(l10n.loginButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Language Switcher ──
                  TextButton.icon(
                    key: const Key('languageSwitcher'),
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
      ),
    );
  }
}
