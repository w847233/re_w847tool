import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/app_shell.dart';
import 'features/home_page.dart';
import 'features/settings_page.dart';
import 'features/tool_pages.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomePage());
            },
          ),
          GoRoute(
            path: '/tools/:toolId',
            pageBuilder: (context, state) {
              final toolId = state.pathParameters['toolId'] ?? 'notes';
              return NoTransitionPage(child: ToolPage(toolId: toolId));
            },
          ),
          GoRoute(
            path: '/settings',
            redirect: (context, state) => '/settings/personalization',
          ),
          GoRoute(
            path: '/settings/:section',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: SettingsPage(
                  section: state.pathParameters['section'] ?? 'personalization',
                ),
              );
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('页面不存在：${state.uri.path}'))),
  );
});
