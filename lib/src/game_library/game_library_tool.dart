import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../ui/app_panel.dart';
import '../ui/latest_snack_bar.dart';
import 'game_library_models.dart';
import 'game_library_repository.dart';

class GameLibraryTool extends ConsumerStatefulWidget {
  const GameLibraryTool({super.key});

  @override
  ConsumerState<GameLibraryTool> createState() => _GameLibraryToolState();
}

class _GameLibraryToolState extends ConsumerState<GameLibraryTool> {
  final _titleController = TextEditingController();
  final _coverController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(gameLibraryItemsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final form = _AddGamePanel(
          titleController: _titleController,
          coverController: _coverController,
          saving: _saving,
          onSave: _addGame,
        );
        final library = AppPanel(
          title: '我的游戏',
          child: itemsState.when(
            data: (items) => _GameLibraryGrid(items: items),
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: '游戏库读取失败',
              message: error.toString(),
            ),
          ),
        );

        if (!wide) {
          return Column(children: [form, const SizedBox(height: 16), library]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: form),
            const SizedBox(width: 16),
            Expanded(child: library),
          ],
        );
      },
    );
  }

  Future<void> _addGame() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showLatestSnackBar(const SnackBar(content: Text('请先输入游戏标题')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(gameLibraryRepositoryProvider)
          .addGame(title: title, cover: _coverController.text);
      _titleController.clear();
      _coverController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showLatestSnackBar(SnackBar(content: Text('已添加：$title')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _AddGamePanel extends StatelessWidget {
  const _AddGamePanel({
    required this.titleController,
    required this.coverController,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController coverController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: '添加游戏',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '游戏标题'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: coverController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '封面 URL 或本地路径',
              hintText: '可选，例如 https://... 或 C:\\Games\\cover.jpg',
            ),
            onSubmitted: (_) {
              if (!saving) {
                onSave();
              }
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: Icon(saving ? Icons.hourglass_empty : Icons.add),
              label: Text(saving ? '添加中...' : '添加游戏'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameLibraryGrid extends StatelessWidget {
  const _GameLibraryGrid({required this.items});

  final List<GameLibraryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.videogame_asset_outlined,
        title: '还没有添加游戏',
        message: '先添加一个常玩的游戏吧。',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _GameCard(item: items[index]);
          },
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.item});

  final GameLibraryItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _GameCover(cover: item.cover, title: item.title),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCover extends StatelessWidget {
  const _GameCover({required this.cover, required this.title});

  final String cover;
  final String title;

  @override
  Widget build(BuildContext context) {
    final source = cover.trim();
    if (source.isEmpty) {
      return _CoverPlaceholder(title: title);
    }

    final uri = Uri.tryParse(source);
    final isNetwork =
        uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) {
      return _CoverPlaceholder(title: title);
    }

    if (isNetwork) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: errorBuilder,
      );
    }

    return Image.file(
      File(source),
      fit: BoxFit.cover,
      errorBuilder: errorBuilder,
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xfffff4ea), Color(0xffead9c8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.videogame_asset_outlined,
              size: 112,
              color: AppColors.accent.withValues(alpha: 0.16),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videogame_asset_outlined,
                  size: 42,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
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
