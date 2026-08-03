import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/locale_provider.dart';
import '../../core/providers.dart';
import '../../domain/permission_checker.dart';
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
    final permChecker = ref.watch(permissionCheckerProvider);

    final roleStr = user?.role;
    final canManageUsers = permChecker.canManageUsers(roleStr);
    final canManageBackup = permChecker.canManageBackup(roleStr);
    final canManageBranding = permChecker.canManageBranding(roleStr);
    final canManageSuppliers = permChecker.canManageSuppliers(roleStr);
    final canManageShifts = permChecker.canManageShifts(roleStr);
    final canManageReturns = permChecker.canManageReturns(roleStr);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        elevation: 0,
        actions: [
          // Language toggle
          IconButton(
            key: const Key('languageToggle'),
            icon: const Icon(Icons.language),
            tooltip: l10n.languageLabel,
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),
          // Branding (Admin only)
          if (canManageBranding)
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
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Hero Banner ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00695C), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withAlpha(50),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(50), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.welcomeBack}, ${user?.username ?? ''}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (user?.role ?? 'kasir').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              locale.languageCode == 'id' ? '🇮🇩 ID' : '🇬🇧 EN',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PrimaryWorkflowAction(
                            role: permChecker.parseRole(roleStr),
                            onStartSale: () => _navigate(context, const PosScreen()),
                            onReceiveStock: () => _navigate(context, const PurchaseOrderScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 1: Daily Overview ──
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.dailySummarySection,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                todayStats.when(
                  data: (stats) => _StatsRow(stats: stats, l10n: l10n),
                  loading: () => const SizedBox(
                    height: 90,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => OutlinedButton.icon(
                    key: const Key('retryDashboardStatsBtn'),
                    onPressed: () => ref.invalidate(_todayStatsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry dashboard status'),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 2: Platform Modules ──
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.platformModulesSection,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),


                // ── Responsive Navigation Grid ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 1000
                        ? 3
                        : width > 640
                            ? 2
                            : 1;
                    final childAspectRatio = width > 1000
                        ? 2.6
                        : width > 640
                            ? 2.3
                            : 2.8;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _NavCard(
                          key: const Key('navPosBtn'),
                          icon: Icons.point_of_sale_rounded,
                          color: AppTheme.cardPOS,
                          title: l10n.posTitle,
                          subtitle: l10n.posSubtitle,
                          isEnabled: true,
                          onTap: () => _navigate(context, const PosScreen()),
                        ),
                        _NavCard(
                          key: const Key('navShiftsBtn'),
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppTheme.cardShifts,
                          title: l10n.shiftTitle,
                          subtitle: l10n.shiftSubtitle,
                          isEnabled: canManageShifts,
                          restrictionTooltip: 'Admin & Kasir only',
                          onTap: () =>
                              _navigate(context, const ShiftManagementScreen()),
                        ),
                        _NavCard(
                          key: const Key('navReturnsBtn'),
                          icon: Icons.assignment_return_rounded,
                          color: AppTheme.cardReturns,
                          title: l10n.returnsTitle,
                          subtitle: l10n.returnsSubtitle,
                          isEnabled: canManageReturns,
                          restrictionTooltip: 'Admin & Kasir only',
                          onTap: () => _navigate(context, const ReturnScreen()),
                        ),
                        _NavCard(
                          key: const Key('navSuppliersBtn'),
                          icon: Icons.local_shipping_rounded,
                          color: AppTheme.cardSuppliers,
                          title: l10n.suppliersTitle,
                          subtitle: l10n.suppliersSubtitle,
                          isEnabled: canManageSuppliers,
                          restrictionTooltip: 'Admin & Inventory only',
                          onTap: () =>
                              _navigate(context, const PurchaseOrderScreen()),
                        ),
                        _NavCard(
                          key: const Key('navInventoryBtn'),
                          icon: Icons.inventory_2_rounded,
                          color: AppTheme.cardInventory,
                          title: l10n.inventoryTitle,
                          subtitle: l10n.inventorySubtitle,
                          isEnabled: true,
                          onTap: () =>
                              _navigate(context, const ProductListScreen()),
                        ),
                        _NavCard(
                          key: const Key('navAlertsBtn'),
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.cardAlerts,
                          title: l10n.alertsTitle,
                          subtitle: l10n.alertsSubtitle,
                          isEnabled: true,
                          onTap: () => _navigate(context, const AlertsScreen()),
                        ),
                        _NavCard(
                          key: const Key('navReportsBtn'),
                          icon: Icons.bar_chart_rounded,
                          color: AppTheme.cardReports,
                          title: l10n.reportsTitle,
                          subtitle: l10n.reportsSubtitle,
                          isEnabled: true,
                          onTap: () => _navigate(context, const ReportsScreen()),
                        ),
                        _NavCard(
                          key: const Key('navBackupBtn'),
                          icon: Icons.backup_rounded,
                          color: AppTheme.cardBackup,
                          title: l10n.backupTitle,
                          subtitle: l10n.backupSubtitle,
                          isEnabled: canManageBackup,
                          restrictionTooltip: 'Admin role required',
                          onTap: () => _navigate(context, const BackupScreen()),
                        ),
                        _NavCard(
                          key: const Key('navUsersBtn'),
                          icon: Icons.people_alt_rounded,
                          color: AppTheme.cardUsers,
                          title: l10n.userManagementTitle,
                          subtitle: l10n.userManagementSubtitle,
                          isEnabled: canManageUsers,
                          restrictionTooltip: 'Admin role required',
                          onTap: () =>
                              _navigate(context, const UserManagementScreen()),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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

// ── Primary Action ──

class _PrimaryWorkflowAction extends StatelessWidget {
  const _PrimaryWorkflowAction({
    required this.role,
    required this.onStartSale,
    required this.onReceiveStock,
  });

  final Role role;
  final VoidCallback onStartSale;
  final VoidCallback onReceiveStock;

  @override
  Widget build(BuildContext context) {
    final inventory = role == Role.inventory;
    return ElevatedButton.icon(
      key: Key(inventory ? 'primaryReceiveStockBtn' : 'primaryStartSaleBtn'),
      onPressed: inventory ? onReceiveStock : onStartSale,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(
        inventory ? Icons.inventory_2_outlined : Icons.point_of_sale_rounded,
        size: 18,
      ),
      label: Text(
        inventory ? 'Receive Stock' : 'Start Sale',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final items = [
          _StatChip(
            icon: Icons.receipt_long_rounded,
            color: AppTheme.infoColor,
            label: l10n.todaySales,
            value: '${stats.salesCount}',
          ),
          _StatChip(
            icon: Icons.payments_rounded,
            color: AppTheme.successColor,
            label: l10n.todayRevenue,
            value: formatIdr(stats.revenue),
          ),
          _StatChip(
            icon: Icons.inventory_rounded,
            color: AppTheme.warningColor,
            label: l10n.lowStockAlerts,
            value: '${stats.lowStockCount}',
          ),
          _StatChip(
            icon: Icons.event_busy_rounded,
            color: AppTheme.dangerColor,
            label: l10n.expiringAlerts,
            value: '${stats.expiringCount}',
          ),
        ];

        if (isWide) {
          return Row(
            children: items
                .map((item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: item,
                      ),
                    ))
                .toList(),
          );
        }

        // Mobile: 2x2 Grid
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: items,
        );
      },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  final bool isEnabled;
  final String? restrictionTooltip;
  final VoidCallback onTap;

  const _NavCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isEnabled = true,
    this.restrictionTooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? color : Colors.grey.shade400;

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [effectiveColor, effectiveColor.withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? const Color(0xFF1A1A2E) : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled
                      ? subtitle
                      : (restrictionTooltip ?? 'Restricted'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isEnabled)
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            )
          else
            Tooltip(
              message: restrictionTooltip ?? 'Restricted role',
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isEnabled ? onTap : null,
        child: cardContent,
      ),
    );
  }
}

