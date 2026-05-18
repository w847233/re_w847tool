import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const deferredNavigationDelay = Duration(milliseconds: 180);
const drawerDeferredNavigationDelay = Duration(milliseconds: 260);
const deferredToolContentDelay = Duration(milliseconds: 120);

Timer? _pendingNavigationTimer;

void goAfterTapFeedback(
  BuildContext context,
  String route, {
  Duration delay = deferredNavigationDelay,
}) {
  final router = GoRouter.of(context);
  final currentPath = GoRouterState.of(context).uri.path;

  _pendingNavigationTimer?.cancel();
  if (currentPath == route) {
    return;
  }

  _pendingNavigationTimer = Timer(delay, () {
    _pendingNavigationTimer = null;
    router.go(route);
  });
}
