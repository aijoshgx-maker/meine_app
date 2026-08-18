import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Schlanker Wrapper um flutter_local_notifications: ein einziger,
// wiederverwendeter Reminder-Slot für "heute fällige Karten", täglich neu
// geplant (bei jedem Dashboard-Aufbau), nicht exakt getaktet
// (inexactAllowWhileIdle) – siehe Plan für die Begründung.
//
// Vereinfachung: Zeitzone wird fest auf Europe/Berlin gesetzt, statt sie
// per Zusatzpaket vom Gerät abzufragen – ausreichend für diese persönliche
// App, die nicht für andere Zeitzonen gedacht ist.
class NotificationService {
  static const _dueReminderId = 1;
  static const _erinnerungsStunde = 18;
  static const _erinnerungsMinute = 0;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Ob lokale Benachrichtigungen auf dieser Plattform überhaupt existieren.
  ///
  /// flutter_local_notifications hat keine Web-Implementierung: Jeder
  /// Plugin-Aufruf würde dort mit einer MissingPluginException abbrechen -
  /// beim Start also die ganze App. Der Service steigt deshalb selbst früh
  /// aus, statt sich darauf zu verlassen, dass jeder Aufrufer daran denkt.
  static bool get unterstuetzt =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    // Zeitzonen sind reine Dart-Logik und schaden nirgends.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

    if (!unterstuetzt) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit),
    );
  }

  Future<bool> berechtigungAnfragen() async {
    if (!unterstuetzt) return false;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final erlaubt = await androidPlugin?.requestNotificationsPermission();
    return erlaubt ?? false;
  }

  Future<void> faelligeErinnerungPlanen(int anzahlFaellig) async {
    if (!unterstuetzt) return;
    if (anzahlFaellig <= 0) {
      await erinnerungAbbrechen();
      return;
    }

    final termin = naechsteTageszeit(
      DateTime.now(),
      tz.local,
      stunde: _erinnerungsStunde,
      minute: _erinnerungsMinute,
    );

    await _plugin.zonedSchedule(
      id: _dueReminderId,
      title: 'AP2 Lern-App',
      body: 'Du hast $anzahlFaellig Karten fällig.',
      scheduledDate: termin,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'due_reminder',
          'Fällige Wiederholungen',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> erinnerungAbbrechen() async {
    if (!unterstuetzt) return;
    await _plugin.cancel(id: _dueReminderId);
  }
}

// Reine Terminberechnung, getrennt vom Plugin-Aufruf, damit sie ohne
// Plattform-Kanal testbar ist: nächster Zeitpunkt heute (falls noch nicht
// vorbei) oder morgen zur angegebenen Uhrzeit.
tz.TZDateTime naechsteTageszeit(
  DateTime jetzt,
  tz.Location ort, {
  required int stunde,
  required int minute,
}) {
  final jetztInZeitzone = tz.TZDateTime.from(jetzt, ort);
  var termin = tz.TZDateTime(
    ort,
    jetztInZeitzone.year,
    jetztInZeitzone.month,
    jetztInZeitzone.day,
    stunde,
    minute,
  );
  if (termin.isBefore(jetztInZeitzone)) {
    termin = termin.add(const Duration(days: 1));
  }
  return termin;
}
