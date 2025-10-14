import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fitnessrecording/features/fitness/presentation/app_pages.dart';

final AppRouter appRouter = AppRouter._();

class AppRouter extends ChangeNotifier {
  AppRouter._();

  final AppRouteInformationParser parser = AppRouteInformationParser();
  late final AppRouterDelegate delegate = AppRouterDelegate(this);

  String _path = '/';
  String get path => _path;

  void push(String newPath){
    _path = newPath;
    notifyListeners();
  }

  void pop(){
    if(_path == '/') return;
    final uri = Uri.parse(_path);
    final segs = List<String>.of(uri.pathSegments)..removeLast();
    _path = '/${segs.join('/')}';
    if(_path != '/' && _path.endsWith('/')) _path = _path.substring(0, _path.length - 1);
    notifyListeners();
  }

  static AppRouter of(BuildContext context) => (Router.of(context).routerDelegate as AppRouterDelegate).router;
}

class AppRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.path;
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}

class AppRouterDelegate extends RouterDelegate<String> with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AppRouter router;
  AppRouterDelegate(this.router){
    router.addListener(notifyListeners);
  }

  @override
  String get currentConfiguration => router.path;

  @override
  Widget build(BuildContext context){
    final uri = Uri.parse(router.path);
    final page = _matchPage(uri.path);

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          child: page.builder(context, _extractParams(uri, page.path)),
        ),
      ],
      onDidRemovePage: (Page<dynamic> page){
        popRoute();
        notifyListeners();
      },
    );
  }
  
  @override
  Future<bool> popRoute(){
    if(router.path != '/'){
      router.pop();
      notifyListeners();
      return SynchronousFuture(true);
    }
    return SynchronousFuture(false);
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    router._path = configuration;
  }

  AppPage _matchPage(String path){
    for(final p in kAppPages){
      if(_pathMatch(p.path, path)) return p;
    }
    return kAppPages.first;
  }

  bool _pathMatch(String template, String real){
    final t = Uri.parse(template).pathSegments;
    final r = Uri.parse(real).pathSegments;
    if(t.length != r.length) return false;
    for(int i = 0; i < t.length; i++){
      if(t[i].startsWith(':')) continue;
      if(t[i] != r[i]) return false;
    }
    return true;
  }

  RouteParams _extractParams(Uri uri , String template){
    final t = Uri.parse(template).pathSegments;
    final r = uri.pathSegments;
    final params = <String, String>{};
    for(int i = 0; i < t.length; i++){
      if(t[i].startsWith(':')) params[t[i].substring(1)] = r[i];
    }
    return RouteParams(params, uri.queryParameters);
  }
}
