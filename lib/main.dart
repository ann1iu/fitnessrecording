import 'dart:async';
import 'dart:ui';

import 'package:fitnessrecording/features/fitness/presentation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';

/// 应用入口
void main() {
  // 捕获Flutter框架错误
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🐛 FLUTTER ERROR: ${details.exception}');
    debugPrint('📋 STACK TRACE: ${details.stack}');
  };
  
  // 捕获Dart异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🐛 DART ERROR: $error');
    debugPrint('📋 STACK TRACE: $stack');
    return true;
  };
  
  runZonedGuarded(() {
    hierarchicalLoggingEnabled = true;
    debugPrint('🚀 Application starting...');
    runApp(const ProviderScope(child: MyApp()));
  }, (error, stackTrace) {
    debugPrint('🐛 ZONED ERROR: $error');
    debugPrint('📋 STACK TRACE: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fitness Recording',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      routerDelegate: appRouter.delegate,
      routeInformationParser: appRouter.parser,
      debugShowCheckedModeBanner: false,
    );
  }
}