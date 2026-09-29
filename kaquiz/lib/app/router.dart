import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaquiz/screens/auth/auth_startup_screen.dart';
import 'package:kaquiz/screens/home_screen.dart';
import 'package:kaquiz/screens/auth/login_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/startup',
    routes: [
      GoRoute(
        path: '/startup',
        builder: (BuildContext context, GoRouterState state) {
          return const AuthStartupScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
      ),
    ],
  );
}