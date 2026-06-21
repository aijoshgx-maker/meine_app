import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Vorläufiger Startbildschirm. Wird in einer späteren Runde durch das
// Dashboard (Phase 6, gewichteter Score/Kalibrierung) ersetzt.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AP2 Industriemechaniker')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/quiz'),
          child: const Text('Quiz starten'),
        ),
      ),
    );
  }
}
