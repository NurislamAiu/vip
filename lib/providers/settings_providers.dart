import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import '../services/reminder_service.dart';

/// Single shared reminder scheduler.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// Manager-configured, per-device reminder preferences, persisted locally.
final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  return ReminderSettingsNotifier();
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  ReminderSettingsNotifier() : super(const ReminderSettings()) {
    _load();
  }

  static const _key = 'reminder_settings_v1';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        state = ReminderSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('reminder settings load failed: $e');
    }
  }

  Future<void> update(ReminderSettings next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('reminder settings save failed: $e');
    }
  }

  void setArrival(ReminderLead lead) => update(state.copyWith(arrival: lead));
  void setAppointment(ReminderLead lead) =>
      update(state.copyWith(appointment: lead));
  void setDeparture(ReminderLead lead) =>
      update(state.copyWith(departure: lead));
  void setAutoStatus(bool value) => update(state.copyWith(autoStatus: value));
}
