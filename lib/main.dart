import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: DarakApp()));
}

class DarakApp extends ConsumerWidget {
  const DarakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final platform = MediaQuery.platformBrightnessOf(context);
    final brightness = darakThemeBrightness(mode, platform);
    AppColors.current = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

    return MaterialApp.router(
      title: 'دارك وحيك',
      debugShowCheckedModeBanner: false,
      theme: darakTheme(mode, platform),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        Widget frame = child!;
        if (width > 520) {
          frame = ColoredBox(
            color: const Color(0xFF05241C),
            child: Center(
              child: Container(
                width: 430,
                height: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                    right: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                    top: BorderSide.none,
                    bottom: BorderSide.none,
                  ),
                ),
                child: frame,
              ),
            ),
          );
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: frame,
        );
      },
      routerConfig: appRouter.config(),
    );
  }
}
