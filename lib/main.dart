import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/app.dart';
import 'package:shaya_ai/core/app_bootstrap.dart';
import 'package:shaya_ai/core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(
    ProviderScope(
      overrides: [appBootstrapProvider.overrideWithValue(bootstrap)],
      child: const ShayaApp(),
    ),
  );
}
