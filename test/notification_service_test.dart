import 'package:flutter_test/flutter_test.dart';
import 'package:meine_app/core/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Nur die reine Terminberechnung ist hier testbar – der eigentliche
// Plugin-Aufruf (Plattformkanal) braucht ein echtes Gerät/Emulator und wird
// dort manuell verifiziert (Android-13-Berechtigung, tatsächliche Anzeige).
void main() {
  tz_data.initializeTimeZones();
  final berlin = tz.getLocation('Europe/Berlin');

  test('plant für heute, wenn die Uhrzeit noch nicht vorbei ist', () {
    final jetzt = tz.TZDateTime(berlin, 2026, 6, 23, 10, 0);
    final termin = naechsteTageszeit(jetzt, berlin, stunde: 18, minute: 0);

    expect(termin.year, 2026);
    expect(termin.month, 6);
    expect(termin.day, 23);
    expect(termin.hour, 18);
  });

  test('plant für morgen, wenn die Uhrzeit heute schon vorbei ist', () {
    final jetzt = tz.TZDateTime(berlin, 2026, 6, 23, 20, 0);
    final termin = naechsteTageszeit(jetzt, berlin, stunde: 18, minute: 0);

    expect(termin.day, 24);
    expect(termin.hour, 18);
  });
}
