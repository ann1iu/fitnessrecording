import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';

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