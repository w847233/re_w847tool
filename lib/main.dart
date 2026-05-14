import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/app_router.dart';
import 'src/settings/font_weight_option.dart';
import 'src/settings/settings_repository.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: PersonalToolboxApp()));
}

class PersonalToolboxApp extends ConsumerWidget {
  const PersonalToolboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferredWeight = ref.watch(preferredFontWeightProvider);
    final router = ref.watch(appRouterProvider);
    final fontWeight = preferredWeight.maybeWhen(
      data: (value) => value,
      orElse: () => defaultFontWeightOption.weight,
    );

    return MaterialApp.router(
      title: '个人工具箱',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: buildAppTheme(fontWeight),
      routerConfig: router,
    );
  }
}
