import 'package:flutter/material.dart';
import 'router.dart';

class KaquizApp extends StatelessWidget {
  const KaquizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kaquiz',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
