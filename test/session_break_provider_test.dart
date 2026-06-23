import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/features/quiz/providers/session_break_provider.dart';

void main() {
  testWidgets('sessionBreakProvider wird nach ~27 Minuten genau einmal true', (
    tester,
  ) async {
    late bool zustand;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            zustand = ref.watch(sessionBreakProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(zustand, false);

    await tester.pump(const Duration(minutes: 26));
    expect(zustand, false);

    await tester.pump(const Duration(minutes: 2));
    expect(zustand, true);
  });
}
