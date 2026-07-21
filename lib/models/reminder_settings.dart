/// One reminder rule: whether it is on and how long before the event to fire.
class ReminderLead {
  const ReminderLead({this.enabled = true, this.minutes = 120});

  final bool enabled;
  final int minutes;

  ReminderLead copyWith({bool? enabled, int? minutes}) => ReminderLead(
        enabled: enabled ?? this.enabled,
        minutes: minutes ?? this.minutes,
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'minutes': minutes};

  factory ReminderLead.fromJson(Map<String, dynamic> json) => ReminderLead(
        enabled: json['enabled'] as bool? ?? true,
        minutes: json['minutes'] as int? ?? 120,
      );
}

/// Per-device notification preferences the manager configures in Settings.
class ReminderSettings {
  const ReminderSettings({
    this.arrival = const ReminderLead(minutes: 120),
    this.appointment = const ReminderLead(minutes: 30),
    this.departure = const ReminderLead(minutes: 1440),
    this.autoStatus = false,
  });

  /// Lead time before a client's arrival.
  final ReminderLead arrival;

  /// Lead time before a doctor appointment.
  final ReminderLead appointment;

  /// Lead time before a departure.
  final ReminderLead departure;

  /// When on, client statuses advance automatically to match the schedule.
  final bool autoStatus;

  ReminderSettings copyWith({
    ReminderLead? arrival,
    ReminderLead? appointment,
    ReminderLead? departure,
    bool? autoStatus,
  }) =>
      ReminderSettings(
        arrival: arrival ?? this.arrival,
        appointment: appointment ?? this.appointment,
        departure: departure ?? this.departure,
        autoStatus: autoStatus ?? this.autoStatus,
      );

  Map<String, dynamic> toJson() => {
        'arrival': arrival.toJson(),
        'appointment': appointment.toJson(),
        'departure': departure.toJson(),
        'autoStatus': autoStatus,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    ReminderLead lead(String key, int fallback) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return ReminderLead.fromJson(raw);
      return ReminderLead(minutes: fallback);
    }

    return ReminderSettings(
      arrival: lead('arrival', 120),
      appointment: lead('appointment', 30),
      departure: lead('departure', 1440),
      autoStatus: json['autoStatus'] as bool? ?? false,
    );
  }
}

/// Human-readable label for a lead time in minutes ("за 2 часа", "за 1 день").
String leadLabel(int minutes) {
  if (minutes % 1440 == 0) {
    final d = minutes ~/ 1440;
    return 'за $d ${_plural(d, 'день', 'дня', 'дней')}';
  }
  if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    return 'за $h ${_plural(h, 'час', 'часа', 'часов')}';
  }
  return 'за $minutes мин';
}

String _plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

/// Preset lead options offered in the UI (minutes).
const List<int> kLeadPresets = [15, 30, 60, 120, 180, 360, 720, 1440, 2880];
