import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: DarakApp()));
}

class DarakApp extends StatelessWidget {
  const DarakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'دارك وحيك',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
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
            color: const Color(0xFF050505),
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
