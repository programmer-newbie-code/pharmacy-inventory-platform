import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/locale_provider.dart';
import '../../core/providers.dart';
import '../../core/responsive_layout.dart';
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
import 'update_banner.dart';

/// Quick dashboard stats loaded asynchronously.
final _todayStatsProvider = FutureProvider.autoDispose<_TodayStats>((
  ref,
) async {
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

/// A primary shell destination.
///
/// Primary destinations swap the workspace *inside* the shell so the chrome
/// stays visible. Only drill-down flows use `Navigator.push`.
class _ShellDestination {
  const _ShellDestination({
    required this.id,
    required this.navKey,
    required this.group,
    required this.icon,
    required this.label,
    required this.build,
    IconData? barIcon,
    IconData? barSelectedIcon,
    String? barLabel,
  })  : _barIcon = barIcon,
        _barSelectedIcon = barSelectedIcon,
        _barLabel = barLabel;

  final String id;
  final Key navKey;
  final _ShellGroup group;
  final IconData icon;
  final String label;
  final Widget Function() build;

  final IconData? _barIcon;
  final IconData? _barSelectedIcon;
  final String? _barLabel;

  IconData get barIcon => _barIcon ?? icon;
  IconData get barSelectedIcon => _barSelectedIcon ?? barIcon;

  /// Bottom-bar labels are shorter than sidebar labels for the few
  /// destinations where the long form would wrap.
  String get barLabel => _barLabel ?? label;
}

enum _ShellGroup { dashboard, operations, management }

class PharmacyShell extends ConsumerStatefulWidget {
  const PharmacyShell({super.key});

  @override
  ConsumerState<PharmacyShell> createState() => _PharmacyShellState();
}

class _PharmacyShellState extends ConsumerState<PharmacyShell> {
  Widget? _workspace;
  String _selected = 'dashboard';

  /// Built lazily so the dashboard receives [_select], letting its nav-cards
  /// swap the workspace inside the shell instead of pushing over it.
  Widget get _currentWorkspace =>
      _workspace ??= HomeScreen(onSelectDestination: _select);

  void _select(String id, Widget screen) {
    setState(() {
      _selected = id;
      _workspace = screen;
    });
  }

  /// The destinations the current role may reach, in shell order.
  List<_ShellDestination> _destinationsFor(
    AppLocalizations l10n,
    PermissionChecker permission,
    String? role,
  ) {
    return [
      _ShellDestination(
        id: 'dashboard',
        navKey: const Key('desktopNavDashboard'),
        group: _ShellGroup.dashboard,
        icon: Icons.dashboard_rounded,
        label: l10n.dashboardTitle,
        barIcon: Icons.dashboard_outlined,
        barSelectedIcon: Icons.dashboard,
        barLabel: l10n.dashboardNav,
        build: () => HomeScreen(onSelectDestination: _select),
      ),
      _ShellDestination(
        id: 'pos',
        navKey: const Key('desktopNavPos'),
        group: _ShellGroup.operations,
        icon: Icons.point_of_sale_rounded,
        label: l10n.posTitle,
        barIcon: Icons.point_of_sale_outlined,
        barSelectedIcon: Icons.point_of_sale,
        build: () => const PosScreen(),
      ),
      _ShellDestination(
        id: 'inventory',
        navKey: const Key('desktopNavInventory'),
        group: _ShellGroup.operations,
        icon: Icons.inventory_2_rounded,
        label: l10n.inventoryTitle,
        barIcon: Icons.inventory_2_outlined,
        barSelectedIcon: Icons.inventory_2,
        build: () => const ProductListScreen(),
      ),
      _ShellDestination(
        id: 'alerts',
        navKey: const Key('desktopNavAlerts'),
        group: _ShellGroup.operations,
        icon: Icons.warning_amber_rounded,
        label: l10n.alertsTitle,
        build: () => const AlertsScreen(),
      ),
      if (permission.canManageShifts(role))
        _ShellDestination(
          id: 'shifts',
          navKey: const Key('desktopNavShifts'),
          group: _ShellGroup.operations,
          icon: Icons.account_balance_wallet_rounded,
          label: l10n.shiftTitle,
          build: () => const ShiftManagementScreen(),
        ),
      if (permission.canManageReturns(role))
        _ShellDestination(
          id: 'returns',
          navKey: const Key('desktopNavReturns'),
          group: _ShellGroup.operations,
          icon: Icons.assignment_return_rounded,
          label: l10n.returnsTitle,
          build: () => const ReturnScreen(),
        ),
      if (permission.canManageSuppliers(role))
        _ShellDestination(
          id: 'suppliers',
          navKey: const Key('desktopNavSuppliers'),
          group: _ShellGroup.management,
          icon: Icons.local_shipping_rounded,
          label: l10n.suppliersTitle,
          build: () => const PurchaseOrderScreen(),
        ),
      _ShellDestination(
        id: 'reports',
        navKey: const Key('desktopNavReports'),
        group: _ShellGroup.management,
        icon: Icons.bar_chart_rounded,
        label: l10n.reportsTitle,
        build: () => const ReportsScreen(),
      ),
      if (permission.canManageBackup(role))
        _ShellDestination(
          id: 'backup',
          navKey: const Key('desktopNavBackup'),
          group: _ShellGroup.management,
          icon: Icons.backup_rounded,
          label: l10n.backupTitle,
          build: () => const BackupScreen(),
        ),
      if (permission.canManageUsers(role))
        _ShellDestination(
          id: 'users',
          navKey: const Key('desktopNavUsers'),
          group: _ShellGroup.management,
          icon: Icons.people_alt_rounded,
          label: l10n.userManagementTitle,
          build: () => const UserManagementScreen(),
        ),
    ];
  }

  /// Destinations that get a dedicated bottom-bar slot. The rest live behind
  /// the More sheet, which keeps the bar at four slots.
  static const _barDestinationIds = ['dashboard', 'pos', 'inventory'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permission = ref.watch(permissionCheckerProvider);
    final role = ref.watch(authSessionProvider)?.role;
    final photoPath = ref.watch(authSessionProvider)?.photoPath;
    final destinations = _destinationsFor(l10n, permission, role);
    final actions = _ShellActions(
      l10n: l10n,
      canManageBranding: permission.canManageBranding(role),
      onToggleLocale: () => ref.read(localeProvider.notifier).toggleLocale(),
      onLogout: () => ref.read(authSessionProvider.notifier).logout(),
    );

    // Layout branches on viewport width only, never on host platform: a
    // 1280px Windows window and an Android tablet in landscape are the same
    // layout problem. Windows launches at 1280x720 so it lands on the sidebar.
    final usesSidebar =
        AppBreakpointWidth.fromWidth(MediaQuery.sizeOf(context).width)
            .usesSidebar;

    if (usesSidebar) {
      return Scaffold(
        body: Row(children: [
          _DesktopSidebar(
            l10n: l10n,
            destinations: destinations,
            actions: actions,
            photoPath: photoPath,
            selectedId: _selected,
            onSelect: _select,
          ),
          Expanded(child: _currentWorkspace),
        ]),
      );
    }

    final barDestinations = destinations
        .where((d) => _barDestinationIds.contains(d.id))
        .toList();
    final overflowDestinations = destinations
        .where((d) => !_barDestinationIds.contains(d.id))
        .toList();
    final selectedBarIndex =
        barDestinations.indexWhere((d) => d.id == _selected);

    return Scaffold(
      body: _currentWorkspace,
      bottomNavigationBar: NavigationBar(
        key: const Key('mobileShellNavigation'),
        // A destination reached through the More sheet keeps More highlighted
        // rather than falsely reporting Dashboard as selected.
        selectedIndex:
            selectedBarIndex >= 0 ? selectedBarIndex : barDestinations.length,
        onDestinationSelected: (index) {
          if (index == barDestinations.length) {
            _showMoreSheet(overflowDestinations, actions);
            return;
          }
          final destination = barDestinations[index];
          _select(destination.id, destination.build());
        },
        destinations: [
          for (final destination in barDestinations)
            NavigationDestination(
              icon: Icon(destination.barIcon),
              selectedIcon: Icon(destination.barSelectedIcon),
              label: destination.barLabel,
            ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.moreNav,
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(
    List<_ShellDestination> overflow,
    _ShellActions actions,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final destination in overflow)
              ListTile(
                key: Key('moreNav_${destination.id}'),
                leading: Icon(destination.icon),
                title: Text(destination.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _select(destination.id, destination.build());
                },
              ),
            const Divider(),
            // Global actions have no bottom-bar slot, so the More sheet is
            // where they stay reachable below the sidebar breakpoint.
            ...actions.asListTiles(sheetContext, context),
          ],
        ),
      ),
    );
  }
}

/// The shell-wide actions that are not destinations: language, help, branding,
/// and logout. Rendered as icons in the sidebar and as rows in the More sheet.
class _ShellActions {
  const _ShellActions({
    required this.l10n,
    required this.canManageBranding,
    required this.onToggleLocale,
    required this.onLogout,
  });

  final AppLocalizations l10n;
  final bool canManageBranding;
  final VoidCallback onToggleLocale;
  final VoidCallback onLogout;

  void _openBranding(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const PharmacyBrandingDialog(),
      );

  void _openHelp(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const QuickGuideDialog(),
      );

  List<Widget> asIconButtons(BuildContext context) => [
        IconButton(
          key: const Key('languageToggle'),
          icon: const Icon(Icons.language),
          tooltip: l10n.languageLabel,
          onPressed: onToggleLocale,
        ),
        if (canManageBranding)
          IconButton(
            key: const Key('brandingButton'),
            icon: const Icon(Icons.storefront),
            tooltip: l10n.brandingTitle,
            onPressed: () => _openBranding(context),
          ),
        IconButton(
          key: const Key('helpButton'),
          icon: const Icon(Icons.help_outline),
          tooltip: l10n.helpTitle,
          onPressed: () => _openHelp(context),
        ),
        IconButton(
          key: const Key('logoutButton'),
          icon: const Icon(Icons.logout),
          tooltip: l10n.logoutButton,
          onPressed: onLogout,
        ),
      ];

  /// [sheetContext] is the bottom sheet's own context and is popped before each
  /// action runs. [hostContext] outlives the sheet, so dialogs are opened from
  /// it — opening a dialog from a popped context would throw.
  List<Widget> asListTiles(
    BuildContext sheetContext,
    BuildContext hostContext,
  ) =>
      [
        ListTile(
          key: const Key('languageToggle'),
          leading: const Icon(Icons.language),
          title: Text(l10n.languageLabel),
          onTap: () {
            Navigator.pop(sheetContext);
            onToggleLocale();
          },
        ),
        if (canManageBranding)
          ListTile(
            key: const Key('brandingButton'),
            leading: const Icon(Icons.storefront),
            title: Text(l10n.brandingTitle),
            onTap: () {
              Navigator.pop(sheetContext);
              _openBranding(hostContext);
            },
          ),
        ListTile(
          key: const Key('helpButton'),
          leading: const Icon(Icons.help_outline),
          title: Text(l10n.helpTitle),
          onTap: () {
            Navigator.pop(sheetContext);
            _openHelp(hostContext);
          },
        ),
        ListTile(
          key: const Key('logoutButton'),
          leading: const Icon(Icons.logout),
          title: Text(l10n.logoutButton),
          onTap: () {
            Navigator.pop(sheetContext);
            onLogout();
          },
        ),
      ];
}

/// Dashboard content. The surrounding chrome (navigation, global actions) is
/// owned by [PharmacyShell]; this widget never builds shell chrome itself.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onSelectDestination});

  /// Supplied by [PharmacyShell] so a nav-card swaps the workspace inside the
  /// shell instead of pushing a route over it. Null in tests that render the
  /// dashboard standalone, which then falls back to [Navigator.push].
  final void Function(String id, Widget screen)? onSelectDestination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authSessionProvider);
    final locale = ref.watch(localeProvider);
    final todayStats = ref.watch(_todayStatsProvider);
    final permChecker = ref.watch(permissionCheckerProvider);

    final roleStr = user?.role;
    final isAdmin = permChecker.parseRole(roleStr) == Role.admin;
    final canManageUsers = permChecker.canManageUsers(roleStr);
    final canManageBackup = permChecker.canManageBackup(roleStr);
    final canManageBranding = permChecker.canManageBranding(roleStr);
    final canManageSuppliers = permChecker.canManageSuppliers(roleStr);
    final canManageShifts = permChecker.canManageShifts(roleStr);
    final canManageReturns = permChecker.canManageReturns(roleStr);

    final isDesktop =
        AppBreakpointWidth.fromWidth(MediaQuery.sizeOf(context).width)
            .usesSidebar;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const UpdateBanner(),
                    // ── Welcome Hero Banner ──
                    if (isDesktop) _DesktopBreadcrumb(l10n: l10n),
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
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withAlpha(50),
                                width: 1.5,
                              ),
                            ),
                            child: user?.photoPath != null &&
                                    File(user!.photoPath!).existsSync()
                                ? ClipOval(
                                    child: Image.file(File(user.photoPath!),
                                        fit: BoxFit.cover))
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 180,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? Colors.amber.withAlpha(50)
                                            : Colors.white.withAlpha(40),
                                        borderRadius: BorderRadius.circular(20),
                                        border: isAdmin
                                            ? Border.all(
                                                color: Colors.amber.shade300
                                                    .withAlpha(150),
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        (user?.role ?? 'kasir').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isAdmin
                                              ? Colors.amber.shade200
                                              : Colors.white,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  locale.languageCode == 'id'
                                      ? '🇮🇩 ID'
                                      : '🇬🇧 EN',
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
                                l10n: l10n,
                                onStartSale: () =>
                                    _navigate(context, 'pos', const PosScreen()),
                                onReceiveStock: () => _navigate(
                                  context,
                                  'suppliers',
                                  const PurchaseOrderScreen(),
                                ),
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
                        const Icon(
                          Icons.analytics_outlined,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.dailySummarySection,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
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
                        label: Text(l10n.retryDashboardStats),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Section 2: Platform Modules ──
                    Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.platformModulesSection,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
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
                              onTap: () =>
                                  _navigate(context, 'pos', const PosScreen()),
                            ),
                            _NavCard(
                              key: const Key('navShiftsBtn'),
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppTheme.cardShifts,
                              title: l10n.shiftTitle,
                              subtitle: l10n.shiftSubtitle,
                              isEnabled: canManageShifts,
                              restrictionTooltip: l10n.adminCashierRestriction,
                              onTap: () => _navigate(
                                context,
                                'shifts',
                                const ShiftManagementScreen(),
                              ),
                            ),
                            _NavCard(
                              key: const Key('navReturnsBtn'),
                              icon: Icons.assignment_return_rounded,
                              color: AppTheme.cardReturns,
                              title: l10n.returnsTitle,
                              subtitle: l10n.returnsSubtitle,
                              isEnabled: canManageReturns,
                              restrictionTooltip: l10n.adminCashierRestriction,
                              onTap: () =>
                                  _navigate(context, 'returns', const ReturnScreen()),
                            ),
                            _NavCard(
                              key: const Key('navSuppliersBtn'),
                              icon: Icons.local_shipping_rounded,
                              color: AppTheme.cardSuppliers,
                              title: l10n.suppliersTitle,
                              subtitle: l10n.suppliersSubtitle,
                              isEnabled: canManageSuppliers,
                              restrictionTooltip:
                                  l10n.adminInventoryRestriction,
                              onTap: () => _navigate(
                                context,
                                'suppliers',
                                const PurchaseOrderScreen(),
                              ),
                            ),
                            _NavCard(
                              key: const Key('navInventoryBtn'),
                              icon: Icons.inventory_2_rounded,
                              color: AppTheme.cardInventory,
                              title: l10n.inventoryTitle,
                              subtitle: l10n.inventorySubtitle,
                              isEnabled: true,
                              onTap: () =>
                                  _navigate(context, 'inventory', const ProductListScreen()),
                            ),
                            _NavCard(
                              key: const Key('navAlertsBtn'),
                              icon: Icons.warning_amber_rounded,
                              color: AppTheme.cardAlerts,
                              title: l10n.alertsTitle,
                              subtitle: l10n.alertsSubtitle,
                              isEnabled: true,
                              onTap: () =>
                                  _navigate(context, 'alerts', const AlertsScreen()),
                            ),
                            _NavCard(
                              key: const Key('navReportsBtn'),
                              icon: Icons.bar_chart_rounded,
                              color: AppTheme.cardReports,
                              title: l10n.reportsTitle,
                              subtitle: l10n.reportsSubtitle,
                              isEnabled: true,
                              onTap: () =>
                                  _navigate(context, 'reports', const ReportsScreen()),
                            ),
                            _NavCard(
                              key: const Key('navBackupBtn'),
                              icon: Icons.backup_rounded,
                              color: AppTheme.cardBackup,
                              title: l10n.backupTitle,
                              subtitle: l10n.backupSubtitle,
                              isEnabled: canManageBackup,
                              restrictionTooltip: l10n.adminOnlyRestriction,
                              onTap: () =>
                                  _navigate(context, 'backup', const BackupScreen()),
                            ),
                            _NavCard(
                              key: const Key('navUsersBtn'),
                              icon: Icons.people_alt_rounded,
                              color: AppTheme.cardUsers,
                              title: l10n.userManagementTitle,
                              subtitle: l10n.userManagementSubtitle,
                              isEnabled: canManageUsers,
                              restrictionTooltip: l10n.adminOnlyRestriction,
                              onTap: () => _navigate(
                                context,
                                'users',
                                const UserManagementScreen(),
                              ),
                            ),
                            _NavCard(
                              key: const Key('navBrandingBtn'),
                              icon: Icons.storefront_rounded,
                              color: Colors.teal,
                              title: l10n.brandingTitle,
                              subtitle: l10n.brandingSubtitle,
                              isEnabled: canManageBranding,
                              restrictionTooltip: l10n.adminOnlyRestriction,
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => const PharmacyBrandingDialog(),
                              ),
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
          );
          return content;
        },
      ),
    );
  }

  /// Navigates to a primary destination.
  ///
  /// Inside the shell this swaps the workspace so the sidebar or bottom bar
  /// stays visible. Standalone (no shell above us) it falls back to pushing a
  /// route. Drill-down flows should call [Navigator.push] directly instead.
  void _navigate(BuildContext context, String id, Widget screen) {
    final select = onSelectDestination;
    if (select != null) {
      select(id, screen);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

// ── Primary Action ──

class _DesktopBreadcrumb extends StatelessWidget {
  const _DesktopBreadcrumb({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Text(
              l10n.desktopWorkspace,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 16),
            ),
            Text(
              l10n.dashboardTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.l10n,
    required this.destinations,
    required this.actions,
    required this.photoPath,
    required this.selectedId,
    required this.onSelect,
  });

  final AppLocalizations l10n;
  final List<_ShellDestination> destinations;
  final _ShellActions actions;
  final String? photoPath;
  final String selectedId;
  final void Function(String id, Widget screen) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktopSidebar'),
      width: 248,
      decoration: BoxDecoration(
        color: const Color(0xFF073F3B),
        border: Border(right: BorderSide(color: Colors.white.withAlpha(18))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/branding/app_icon.png',
                              width: 42,
                              height: 42,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.appTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.sidebarTagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(165),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withAlpha(30),
                        backgroundImage:
                            photoPath != null && File(photoPath!).existsSync()
                                ? FileImage(File(photoPath!))
                                : null,
                        child: photoPath == null ||
                                !File(photoPath!).existsSync()
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 26),
                    ..._groupedItems(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Divider(color: Colors.white.withAlpha(30), height: 1),
            ),
            // Global actions live here so they are reachable from the shell
            // users actually get. They previously sat in an AppBar that never
            // rendered.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: IconTheme(
                data: IconThemeData(color: Colors.white.withAlpha(210)),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: actions.asIconButtons(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(
                child: Text(
                  l10n.poweredByAttribution,
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders destinations grouped by section, with a localized section label
  /// before each group that has at least one permitted destination.
  List<Widget> _groupedItems(BuildContext context) {
    final labels = <_ShellGroup, String>{
      _ShellGroup.dashboard: l10n.dashboardNav,
      _ShellGroup.operations: l10n.operationsNav,
      _ShellGroup.management: l10n.managementNav,
    };
    final widgets = <Widget>[];
    for (final group in _ShellGroup.values) {
      final items = destinations.where((d) => d.group == group).toList();
      if (items.isEmpty) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(_sectionLabel(labels[group]!));
      for (final destination in items) {
        widgets.add(_item(context, destination));
      }
    }
    return widgets;
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withAlpha(130),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _item(BuildContext context, _ShellDestination destination) {
    final selected = destination.id == selectedId;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            key: destination.navKey,
            dense: true,
            selected: selected,
            onTap: () => onSelect(destination.id, destination.build()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            selectedTileColor: AppTheme.accentColor.withAlpha(220),
            iconColor: selected ? Colors.white : Colors.white.withAlpha(185),
            textColor: selected ? Colors.white : Colors.white.withAlpha(210),
            leading: Icon(destination.icon, size: 20),
            title: Text(
              destination.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            trailing: selected
                ? const Icon(Icons.chevron_right, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}

class _PrimaryWorkflowAction extends StatelessWidget {
  const _PrimaryWorkflowAction({
    required this.role,
    required this.l10n,
    required this.onStartSale,
    required this.onReceiveStock,
  });

  final Role role;
  final AppLocalizations l10n;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        inventory ? Icons.inventory_2_outlined : Icons.point_of_sale_rounded,
        size: 18,
      ),
      label: Text(
        inventory ? l10n.receiveStock : l10n.startSale,
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
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: item,
                    ),
                  ),
                )
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
    final l10n = AppLocalizations.of(context)!;
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
                    color: isEnabled
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled ? subtitle : (restrictionTooltip ?? l10n.restrictedSubtitle),
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isEnabled ? Colors.grey.shade600 : Colors.grey.shade500,
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
              message: restrictionTooltip ?? l10n.restrictedRoleTooltip,
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
