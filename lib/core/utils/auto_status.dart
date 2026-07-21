import '../../models/client.dart';
import '../../models/client_status.dart';

/// Combines a calendar date with an "HH:mm" string into a single DateTime.
DateTime? combineDateTime(DateTime? date, String time) {
  if (date == null) return null;
  final parts = time.split(':');
  if (parts.length == 2) {
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h != null && m != null) {
      return DateTime(date.year, date.month, date.day, h, m);
    }
  }
  return DateTime(date.year, date.month, date.day);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Derives the status a client *should* have at [now], based on the timeline.
///
/// Used by the optional auto-status mode. It is intentionally heuristic:
///  - before arrival            → awaiting arrival
///  - arrived, before the visit → in hotel (or "met" right after landing)
///  - around the appointment    → in treatment
///  - departure day             → preparing departure
///  - after departure           → departed
ClientStatus expectedStatus(Client c, DateTime now) {
  final arrival = combineDateTime(c.arrivalDate, c.arrivalTime);
  final appt = combineDateTime(c.doctorAppointmentDate, c.doctorAppointmentTime);
  final departure = combineDateTime(c.departureDate, c.departureTime);

  if (departure != null && now.isAfter(departure)) {
    return ClientStatus.departed;
  }
  if (appt != null &&
      now.isAfter(appt) &&
      now.isBefore(appt.add(const Duration(hours: 3)))) {
    return ClientStatus.inTreatment;
  }
  if (departure != null && _sameDay(departure, now)) {
    return ClientStatus.preparingDeparture;
  }
  if (arrival != null && now.isAfter(arrival)) {
    // Just landed within the last 2 hours reads as "met"; otherwise settled.
    if (now.isBefore(arrival.add(const Duration(hours: 2)))) {
      return ClientStatus.met;
    }
    return ClientStatus.inHotel;
  }
  return ClientStatus.awaitingArrival;
}
