import 'package:flutter/material.dart';

class ToolCategory {
  const ToolCategory({
    required this.id,
    required this.name,
    required this.order,
  });

  final String id;
  final String name;
  final int order;
}

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.syncEnabled,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final bool syncEnabled;
}

const toolCategories = <ToolCategory>[
  ToolCategory(id: 'records', name: '记录', order: 1),
  ToolCategory(id: 'tasks', name: '任务', order: 2),
  ToolCategory(id: 'time', name: '时间', order: 3),
  ToolCategory(id: 'network', name: '网络', order: 4),
  ToolCategory(id: 'utility', name: '实用', order: 5),
];

const toolDefinitions = <ToolDefinition>[
  ToolDefinition(
    id: 'notes',
    categoryId: 'records',
    name: '便签',
    description: '记录临时想法和常用信息',
    icon: Icons.sticky_note_2_outlined,
    route: '/tools/notes',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'ledger',
    categoryId: 'records',
    name: '记账',
    description: '记录收入、支出和备注',
    icon: Icons.account_balance_wallet_outlined,
    route: '/tools/ledger',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'todos',
    categoryId: 'tasks',
    name: '待办',
    description: '管理待处理事项',
    icon: Icons.checklist_outlined,
    route: '/tools/todos',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'countdown',
    categoryId: 'tasks',
    name: '倒数日',
    description: '追踪重要日期',
    icon: Icons.event_outlined,
    route: '/tools/countdown',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'pomodoro',
    categoryId: 'time',
    name: '番茄钟',
    description: '专注计时和会话记录',
    icon: Icons.timer_outlined,
    route: '/tools/pomodoro',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'dnsLeak',
    categoryId: 'network',
    name: '检测DNS泄露',
    description: '检测 DNS 出口、优选公共 DNS 并写入系统设置',
    icon: Icons.dns_outlined,
    route: '/tools/dnsLeak',
    syncEnabled: false,
  ),
  ToolDefinition(
    id: 'natTraversal',
    categoryId: 'network',
    name: 'NAT隧道打洞',
    description: '检测 NAT 类型并管理 UDP/TCP 穿透转发',
    icon: Icons.hub_outlined,
    route: '/tools/natTraversal',
    syncEnabled: true,
  ),
  ToolDefinition(
    id: 'converter',
    categoryId: 'utility',
    name: '单位换算',
    description: '长度、重量和温度换算',
    icon: Icons.swap_horiz_outlined,
    route: '/tools/converter',
    syncEnabled: false,
  ),
  ToolDefinition(
    id: 'password',
    categoryId: 'utility',
    name: '密码生成',
    description: '生成本地临时密码',
    icon: Icons.key_outlined,
    route: '/tools/password',
    syncEnabled: false,
  ),
  ToolDefinition(
    id: 'steamStatus',
    categoryId: 'utility',
    name: 'Steam 状态',
    description: '管理 Steam 登录、自定义状态和 Rich Presence',
    icon: Icons.sports_esports_outlined,
    route: '/tools/steamStatus',
    syncEnabled: true,
  ),
];

ToolDefinition toolById(String id) {
  return toolDefinitions.firstWhere(
    (tool) => tool.id == id,
    orElse: () => toolDefinitions.first,
  );
}
