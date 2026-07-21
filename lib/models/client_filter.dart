import 'client.dart';
import 'client_status.dart';

/// Quick filters available on the dashboard.
enum ClientFilter {
  all,
  arrivingToday,
  departingToday,
  appointmentToday,
  inHotel,
  inTreatment,
  completed;

  String get label => switch (this) {
        ClientFilter.all => 'All',
        ClientFilter.arrivingToday => 'Arriving today',
        ClientFilter.departingToday => 'Departing today',
        ClientFilter.appointmentToday => 'Appointment today',
        ClientFilter.inHotel => 'In hotel',
        ClientFilter.inTreatment => 'In treatment',
        ClientFilter.completed => 'Completed',
      };

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whether [client] passes this filter for the reference day [now].
  bool matches(Client client, DateTime now) {
    return switch (this) {
      ClientFilter.all => true,
      ClientFilter.arrivingToday => _isSameDay(client.arrivalDate, now),
      ClientFilter.departingToday => _isSameDay(client.departureDate, now),
      ClientFilter.appointmentToday =>
        _isSameDay(client.doctorAppointmentDate, now),
      ClientFilter.inHotel => client.status == ClientStatus.inHotel,
      ClientFilter.inTreatment => client.status == ClientStatus.inTreatment,
      ClientFilter.completed => client.status == ClientStatus.completed,
    };
  }
}
