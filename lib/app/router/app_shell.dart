import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_names.dart';
import '../../core/widgets/sidebar_item_model.dart';

/// Desktop app shell with sidebar navigation, app bar, and content area.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  static const double _sidebarWidth = 220;
  static const double _appBarHeight = 64;

  static final List<SidebarItemModel> _navItems = [
    SidebarItemModel(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      path: RouteNames.dashboardPath,
    ),
    SidebarItemModel(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      path: RouteNames.productsPath,
    ),
    SidebarItemModel(
      label: 'Purchases',
      icon: Icons.shopping_cart_outlined,
      path: RouteNames.purchasesPath,
    ),
    SidebarItemModel(
      label: 'Sales',
      icon: Icons.point_of_sale_outlined,
      path: RouteNames.salesPath,
    ),
    SidebarItemModel(
      label: 'Inventory',
      icon: Icons.warehouse_outlined,
      path: RouteNames.inventoryPath,
    ),
    SidebarItemModel(
      label: 'Expenses',
      icon: Icons.receipt_long_outlined,
      path: RouteNames.expensesPath,
    ),
    SidebarItemModel(
      label: 'Reports',
      icon: Icons.analytics_outlined,
      path: RouteNames.reportsPath,
    ),
    SidebarItemModel(
      label: 'Settings',
      icon: Icons.settings_outlined,
      path: RouteNames.settingsPath,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            width: _sidebarWidth,
            navItems: _navItems,
            currentPath: location,
          ),
          Expanded(
            child: Column(
              children: [
                _AppBar(height: _appBarHeight),
                Expanded(
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.width,
    required this.navItems,
    required this.currentPath,
  });

  final double width;
  final List<SidebarItemModel> navItems;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppConstants.appName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: navItems
                    .map(
                      (item) => _NavItem(
                        item: item,
                        isSelected: _isSelected(currentPath, item.path),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSelected(String current, String path) {
    if (path == RouteNames.dashboardPath) {
      return current == path || current == RouteNames.root;
    }
    return current.startsWith(path);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
  });

  final SidebarItemModel item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go(item.path),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({required this.height});

  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getTitleFromPath(GoRouterState.of(context).uri.path),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitleFromPath(String path) {
    if (path.isEmpty || path == '/') return 'Dashboard';
    final segment = path.split('/').last;
    if (segment.isEmpty) return 'Dashboard';
    return segment[0].toUpperCase() + segment.substring(1);
  }
}
