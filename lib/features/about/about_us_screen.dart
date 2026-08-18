import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// "About Us" screen — Programmer Newbie Studio info.
///
/// Placed as the **last** destination in sidebar / overflow so it is
/// discoverable but never obtrusive to the core pharmacy workflow.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _studioUrl = 'https://programmer-newbie.dev';
  static const _githubUrl =
      'https://github.com/programmer-newbie-code/pharmacy-inventory-platform';
  static const _email = 'support@programmer-newbie.dev';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutUsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Studio Card ──
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? const Color(0x1affffff)
                    : const Color(0x14000000),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Programmer Newbie',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aboutUsStudioTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Visit Studio Website button
                  FilledButton.icon(
                    onPressed: () => _open(_studioUrl),
                    icon: const Icon(Icons.language, size: 18),
                    label: Text(l10n.aboutUsVisitWebsite),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── About Description ──
          Text(
            l10n.aboutUsDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // ── Links ──
          _LinkTile(
            icon: Icons.email_outlined,
            title: l10n.aboutUsContactEmail,
            subtitle: _email,
            onTap: () => _open('mailto:$_email'),
          ),
          _LinkTile(
            icon: Icons.code_rounded,
            title: l10n.aboutUsSourceCode,
            subtitle: 'GitHub',
            onTap: () => _open(_githubUrl),
          ),
          _LinkTile(
            icon: Icons.public_rounded,
            title: l10n.aboutUsWebsite,
            subtitle: 'programmer-newbie.dev',
            onTap: () => _open(_studioUrl),
          ),
          const SizedBox(height: 28),

          // ── App Info ──
          Center(
            child: Text(
              l10n.aboutUsAppInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
