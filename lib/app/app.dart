import 'package:flutter/material.dart';

import 'router.dart';

class Ap2App extends StatelessWidget {
  const Ap2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AP2 Industriemechaniker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
