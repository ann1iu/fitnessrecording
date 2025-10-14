import 'package:flutter/material.dart';
import 'package:fitnessrecording/features/fitness/presentation/pages/workout_dateil_page.dart';
import 'package:fitnessrecording/features/fitness/presentation/pages/home_page.dart';

/// 一条路由配置
class AppPage {
  final String path;          // 路由模板  /detail/:id
  final Widget Function(BuildContext, RouteParams) builder;

  const AppPage(this.path, this.builder);
}

/// 路由参数封装
class RouteParams {
  final Map<String, String> params;   // 路径参数  {id:'123'}
  final Map<String, String> query;    // query 参数 ?name=abc
  const RouteParams(this.params, this.query);
}

/// 1. 注册所有页面 -------------------------------------------------
final List<AppPage> kAppPages = [
  AppPage('/', (_, __) => HomePage()),
  AppPage('/detail/:id', (context, params) {
    final id = int.parse(params.params['id']!);
    return WorkoutDetailPage(workoutId: id);
  }),
  // AppPage('/profile', (_, __) => const ProfilePage()),
];