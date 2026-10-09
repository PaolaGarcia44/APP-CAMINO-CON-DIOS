import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_service.dart';
import 'data/services/notification_service.dart';
import 'routes/app_router.dart';
import 'presentation/providers/content_providers.dart';
import 'presentation/providers/notification_providers.dart';
import 'presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: LuzParaHoyApp()));
}

class LuzParaHoyApp extends ConsumerStatefulWidget {
  const LuzParaHoyApp({super.key});

  @override
  ConsumerState<LuzParaHoyApp> createState() => _LuzParaHoyAppState();
}

class _LuzParaHoyAppState extends ConsumerState<LuzParaHoyApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _tapSubscription;
  DateTime _lastDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Tocar una notificacion con la app abierta lleva a su seccion.
    _tapSubscription = NotificationService.taps.listen((route) {
      ref.read(routerProvider).go(route);
    });
    // Reprogramar al abrir: mantiene la ventana de mensajes diarios al dia y
    // recupera los avisos si cambio la zona horaria.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderSchedulerProvider).rescheduleAll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (now.year != _lastDay.year || now.month != _lastDay.month || now.day != _lastDay.day) {
      // Cambio el dia mientras la app estaba en segundo plano: refrescar el
      // contenido del dia y la programacion de avisos.
      _lastDay = now;
      ref.invalidate(todayProvider);
      ref.read(reminderSchedulerProvider).rescheduleAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
