import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';

class ShayaApp extends ConsumerWidget {
  const ShayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Shaya AI',
      debugShowCheckedModeBanner: false,
      theme: shayaTheme,
      routerConfig: router,
    );
  }
}
