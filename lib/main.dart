import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartstyle/core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final sentryDsn = dotenv.env['SENTRY_DSN'];
  
  if (sentryDsn != null && sentryDsn.isNotEmpty && sentryDsn != 'YOUR_SENTRY_DSN') {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(const ProviderScope(child: SmartStyleApp())),
    );
  } else {
    runApp(const ProviderScope(child: SmartStyleApp()));
  }
}

class SmartStyleApp extends ConsumerWidget {
  const SmartStyleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SmartStyle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B4A6B)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
