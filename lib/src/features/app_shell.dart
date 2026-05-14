import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../tools/tool_registry.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        if (compact) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: const Text('个人工具箱'),
              centerTitle: false,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.border),
              ),
            ),
            drawer: Drawer(
              backgroundColor: AppColors.surface,
              child: SafeArea(child: _NavigationContent(currentPath: path)),
            ),
            body: child,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Row(
            children: [
              SizedBox(
                width: 236,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(child: _NavigationContent(currentPath: path)),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationContent extends StatefulWidget {
  const _NavigationContent({required this.currentPath});

  final String currentPath;

  @override
  State<_NavigationContent> createState() => _NavigationContentState();
}

class _NavigationContentState extends State<_NavigationContent>
    with TickerProviderStateMixin {
  final Set<String> _collapsedCategoryIds = {};

  @override
  void didUpdateWidget(covariant _NavigationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _expandCurrentCategory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedTools = {
      for (final category in toolCategories)
        category: toolDefinitions
            .where((tool) => tool.categoryId == category.id)
            .toList(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Row(
            children: [
              Icon(Icons.widgets_outlined, size: 20, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                '个人工具箱',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            children: [
              _NavButton(
                icon: Icons.home_outlined,
                label: '主页',
                selected: widget.currentPath == '/home',
                onTap: () {
                  final router = GoRouter.of(context);
                  _closeDrawerIfNeeded(context);
                  router.go('/home');
                },
              ),
              for (final entry in groupedTools.entries)
                _CollapsibleToolGroup(
                  category: entry.key,
                  tools: entry.value,
                  currentPath: widget.currentPath,
                  collapsed: _collapsedCategoryIds.contains(entry.key.id),
                  onToggle: () => _toggleCategory(entry.key.id),
                  onNavigate: (route) {
                    final router = GoRouter.of(context);
                    _closeDrawerIfNeeded(context);
                    router.go(route);
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
          child: _NavButton(
            icon: Icons.settings_outlined,
            label: '设置',
            selected: widget.currentPath.startsWith('/settings'),
            onTap: () {
              final router = GoRouter.of(context);
              _closeDrawerIfNeeded(context);
              router.go('/settings/personalization');
            },
          ),
        ),
      ],
    );
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (!_collapsedCategoryIds.add(categoryId)) {
        _collapsedCategoryIds.remove(categoryId);
      }
    });
  }

  void _expandCurrentCategory() {
    final currentTool = toolDefinitions.where(
      (tool) => tool.route == widget.currentPath,
    );
    if (currentTool.isEmpty) {
      return;
    }
    _collapsedCategoryIds.remove(currentTool.first.categoryId);
  }

  void _closeDrawerIfNeeded(BuildContext context) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }
}

class _CollapsibleToolGroup extends StatelessWidget {
  const _CollapsibleToolGroup({
    required this.category,
    required this.tools,
    required this.currentPath,
    required this.collapsed,
    required this.onToggle,
    required this.onNavigate,
  });

  final ToolCategory category;
  final List<ToolDefinition> tools;
  final String currentPath;
  final bool collapsed;
  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final hasSelection = tools.any((tool) => tool.route == currentPath);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(
            label: category.name,
            expanded: !collapsed,
            selected: hasSelection,
            onTap: onToggle,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: collapsed
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final tool in tools)
                        _NavButton(
                          icon: tool.icon,
                          label: tool.name,
                          selected: currentPath == tool.route,
                          onTap: () => onNavigate(tool.route),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: expanded,
      selected: selected,
      label: '$label分类',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Material(
          color: selected ? AppColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      size: 20,
                      color: selected ? AppColors.fg : AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.fg : AppColors.muted,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? AppColors.bg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? AppColors.fg : AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.fg,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
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
