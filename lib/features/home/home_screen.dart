import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

import '../alerts/alerts_screen.dart';
import '../backup/backup_screen.dart';
import '../inventory/product_list_screen.dart';
import '../pos/pos_screen.dart';
import '../users/user_management_screen.dart';
import '../reports/reports_screen.dart';

import '../help/quick_guide_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('helpButton'),
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const QuickGuideDialog(),
              );
            },
          ),
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            key: const Key('navPosBtn'),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('POS Sales Counter'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PosScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('navInventoryBtn'),
            icon: const Icon(Icons.inventory),
            label: const Text('Inventory Catalog'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('navAlertsBtn'),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Expiry & Low Stock Alerts'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('navBackupBtn'),
            icon: const Icon(Icons.backup),
            label: Text(l10n.backupTitle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('navUsersBtn'),
            icon: const Icon(Icons.people),
            label: Text(l10n.userManagementTitle),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('navReportsBtn'),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Laporan & Financial Excel'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
