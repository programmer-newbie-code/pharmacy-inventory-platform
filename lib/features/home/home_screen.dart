import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/locale_provider.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

import '../alerts/alerts_screen.dart';
import '../backup/backup_screen.dart';
import '../inventory/product_list_screen.dart';
import '../pos/pos_screen.dart';
import '../pos/shift_management_screen.dart';
import '../pos/return_screen.dart';
import '../suppliers/purchase_order_screen.dart';
import '../users/user_management_screen.dart';
import '../reports/reports_screen.dart';

import '../settings/pharmacy_branding_dialog.dart';
import '../help/quick_guide_dialog.dart';

/// Quick dashboard stats loaded asynchronously.
final _todayStatsProvider = FutureProvider.autoDispose<_TodayStats>((ref) async {
  final reportRepo = ref.watch(reportRepositoryProvider);
  final alertRepo = ref.watch(alertRepositoryProvider);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final summary = await reportRepo.getSalesSummary(
    startDate: startOfDay,
    endDate: endOfDay,
  );

  final lowStock = await alertRepo.listLowStockProducts();
  final expiring = await alertRepo.listExpiringBatches();

  return _TodayStats(
    salesCount: summary.totalTransactions,
    revenue: summary.totalRevenue,
    lowStockCount: lowStock.length,
    expiringCount: expiring.length,
  );
});

class _TodayStats {
  final int salesCount;
  final double revenue;
  final int lowStockCount;
  final int expiringCount;

  _TodayStats({
    required this.salesCount,
    required this.revenue,
    required this.lowStockCount,
    required this.expiringCount,
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authSessionProvider);
    final locale = ref.watch(localeProvider);
    final todayStats = ref.watch(_todayStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Language toggle
          IconButton(
            key: const Key('languageToggle'),
            icon: const Icon(Icons.language),
            tooltip: l10n.languageLabel,
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),
          // Branding
          IconButton(
            key: const Key('brandingButton'),
            icon: const Icon(Icons.storefront),
            tooltip: l10n.brandingTitle,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const PharmacyBrandingDialog(),
              );
            },
          ),
          // Help
          IconButton(
            key: const Key('helpButton'),
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.helpTitle,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const QuickGuideDialog(),
              );
            },
          ),
          // Logout
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout),
            tooltip: l10n.logoutButton,
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Header ──
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.welcomeBack}, ${user?.username ?? ''}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (user?.role ?? '').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Current language badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    locale.languageCode == 'id' ? '🇮🇩 ID' : '🇬🇧 EN',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Stats ──
            todayStats.when(
              data: (stats) => _StatsRow(stats: stats, l10n: l10n),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // ── Navigation Grid ──
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _NavCard(
                      key: const Key('navPosBtn'),
                      icon: Icons.point_of_sale,
                      color: AppTheme.cardPOS,
                      title: l10n.posTitle,
                      subtitle: l10n.posSubtitle,
                      onTap: () => _navigate(context, const PosScreen()),
                    ),
                    _NavCard(
                      key: const Key('navShiftsBtn'),
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.cardShifts,
                      title: l10n.shiftTitle,
                      subtitle: l10n.shiftSubtitle,
                      onTap: () =>
                          _navigate(context, const ShiftManagementScreen()),
                    ),
                    _NavCard(
                      key: const Key('navReturnsBtn'),
                      icon: Icons.assignment_return,
                      color: AppTheme.cardReturns,
                      title: l10n.returnsTitle,
                      subtitle: l10n.returnsSubtitle,
                      onTap: () => _navigate(context, const ReturnScreen()),
                    ),
                    _NavCard(
                      key: const Key('navSuppliersBtn'),
                      icon: Icons.local_shipping,
                      color: AppTheme.cardSuppliers,
                      title: l10n.suppliersTitle,
                      subtitle: l10n.suppliersSubtitle,
                      onTap: () =>
                          _navigate(context, const PurchaseOrderScreen()),
                    ),
                    _NavCard(
                      key: const Key('navInventoryBtn'),
                      icon: Icons.inventory_2,
                      color: AppTheme.cardInventory,
                      title: l10n.inventoryTitle,
                      subtitle: l10n.inventorySubtitle,
                      onTap: () =>
                          _navigate(context, const ProductListScreen()),
                    ),
                    _NavCard(
                      key: const Key('navAlertsBtn'),
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.cardAlerts,
                      title: l10n.alertsTitle,
                      subtitle: l10n.alertsSubtitle,
                      onTap: () => _navigate(context, const AlertsScreen()),
                    ),
                    _NavCard(
                      key: const Key('navReportsBtn'),
                      icon: Icons.bar_chart_rounded,
                      color: AppTheme.cardReports,
                      title: l10n.reportsTitle,
                      subtitle: l10n.reportsSubtitle,
                      onTap: () => _navigate(context, const ReportsScreen()),
                    ),
                    _NavCard(
                      key: const Key('navBackupBtn'),
                      icon: Icons.backup_rounded,
                      color: AppTheme.cardBackup,
                      title: l10n.backupTitle,
                      subtitle: l10n.backupSubtitle,
                      onTap: () => _navigate(context, const BackupScreen()),
                    ),
                    _NavCard(
                      key: const Key('navUsersBtn'),
                      icon: Icons.people_alt_rounded,
                      color: AppTheme.cardUsers,
                      title: l10n.userManagementTitle,
                      subtitle: l10n.userManagementSubtitle,
                      onTap: () =>
                          _navigate(context, const UserManagementScreen()),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  final _TodayStats stats;
  final AppLocalizations l10n;

  const _StatsRow({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.receipt_long,
            color: AppTheme.infoColor,
            label: l10n.todaySales,
            value: '${stats.salesCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.payments,
            color: AppTheme.successColor,
            label: l10n.todayRevenue,
            value: 'Rp ${stats.revenue.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.inventory,
            color: AppTheme.warningColor,
            label: l10n.lowStockAlerts,
            value: '${stats.lowStockCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.event_busy,
            color: AppTheme.dangerColor,
            label: l10n.expiringAlerts,
            value: '${stats.expiringCount}',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Navigation Card ──

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
