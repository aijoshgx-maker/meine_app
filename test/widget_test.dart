import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meine_app/main.dart';

void main() {
  testWidgets('Dashboard zeigt alle Themenbereiche nach dem Laden an', (
    WidgetTester tester,
  ) async {
    // Ohne echtes Gerät gibt es keine native shared_preferences-Implementierung;
    // dieses Mock lässt LernplanState.initialisieren() trotzdem normal laden.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MeineApp());

    // Direkt nach dem Start läuft das Laden des Lernplans noch.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Warten, bis LernplanState.initialisieren() (asset laden + setState) fertig ist.
    await tester.pumpAndSettle();

    expect(find.text('Fertigungstechnik'), findsOneWidget);
    expect(find.text('Technisches Zeichnen'), findsOneWidget);

    // Die übrigen Themenbereiche liegen außerhalb des sichtbaren Bereichs
    // im Test-Viewport und müssen erst hin-gescrollt werden.
    await tester.dragUntilVisible(
      find.text('Mathematik / Technische Berechnung'),
      find.byType(ListView),
      const Offset(0, -200),
    );

    expect(find.text('Steuerungstechnik'), findsOneWidget);
    expect(find.text('Werkstoffkunde'), findsOneWidget);
    expect(find.text('Mathematik / Technische Berechnung'), findsOneWidget);
  });
}
