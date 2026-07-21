import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/auto_status.dart';
import '../models/client.dart';
import '../models/reminder_settings.dart';

/// Schedules on-device reminders for upcoming client events (arrival,
/// appointment, departure) using the lead times the manager configured.
///
/// Everything runs locally — no server, no APNS — so it works even on the iOS
/// simulator. All work is wrapped in try/catch: a scheduling failure must
/// never crash the app.
class ReminderService {
  ReminderService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vip_reminders',
    'Напоминания',
    description: 'Напоминания о прибытии, приёме и вылете клиентов.',
    importance: Importance.high,
  );

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (e) {
      debugPrint('ReminderService init failed: $e');
    }
  }

  /// Cancels all pending reminders and re-schedules them from [clients] and the
  /// current [settings]. Call whenever clients or settings change.
  Future<void> sync(List<Client> clients, ReminderSettings settings) async {
    await _ensureReady();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();

      for (final c in clients) {
        await _schedule(
          idKey: '${c.id}_arrival',
          eventAt: combineDateTime(c.arrivalDate, c.arrivalTime),
          lead: settings.arrival,
          now: now,
          title: 'Скоро прибытие',
          body: '${_who(c)} — прибытие в ${_hhmm(c.arrivalTime)}.',
        );
        await _schedule(
          idKey: '${c.id}_appointment',
          eventAt: combineDateTime(
              c.doctorAppointmentDate, c.doctorAppointmentTime),
          lead: settings.appointment,
          now: now,
          title: 'Скоро приём у врача',
          body: '${_who(c)} — приём в ${_hhmm(c.doctorAppointmentTime)}.',
        );
        await _schedule(
          idKey: '${c.id}_departure',
          eventAt: combineDateTime(c.departureDate, c.departureTime),
          lead: settings.departure,
          now: now,
          title: 'Скоро вылет',
          body: '${_who(c)} — вылет в ${_hhmm(c.departureTime)}.',
        );
      }
    } catch (e) {
      debugPrint('ReminderService sync failed: $e');
    }
  }

  Future<void> _schedule({
    required String idKey,
    required DateTime? eventAt,
    required ReminderLead lead,
    required DateTime now,
    required String title,
    required String body,
  }) async {
    if (!lead.enabled || eventAt == null) return;
    final fireAt = eventAt.subtract(Duration(minutes: lead.minutes));
    if (!fireAt.isAfter(now)) return; // in the past — skip

    try {
      final scheduled = tz.TZDateTime.from(fireAt, tz.local);
      await _plugin.zonedSchedule(
        idKey.hashCode & 0x7fffffff,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('ReminderService schedule "$idKey" failed: $e');
    }
  }

  String _who(Client c) => c.name.trim().isEmpty ? 'Клиент' : c.name.trim();

  String _hhmm(String time) =>
      time.trim().isEmpty ? 'ближайшее время' : time.trim();
}
