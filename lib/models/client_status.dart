import 'package:flutter/material.dart';

/// Lifecycle of a VIP client, from expected arrival through completion.
///
/// Each status carries its own accent color and icon for the UI.
enum ClientStatus {
  awaitingArrival,
  met,
  inHotel,
  inTreatment,
  preparingDeparture,
  departed,
  completed;

  String get asString => name;

  static ClientStatus fromString(String? value) {
    return ClientStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ClientStatus.awaitingArrival,
    );
  }

  String get label => switch (this) {
        ClientStatus.awaitingArrival => 'Awaiting arrival',
        ClientStatus.met => 'Met',
        ClientStatus.inHotel => 'In hotel',
        ClientStatus.inTreatment => 'In treatment',
        ClientStatus.preparingDeparture => 'Preparing departure',
        ClientStatus.departed => 'Departed',
        ClientStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        ClientStatus.awaitingArrival => const Color(0xFF3B82F6), // blue
        ClientStatus.met => const Color(0xFF06B6D4), // cyan
        ClientStatus.inHotel => const Color(0xFF8B5CF6), // violet
        ClientStatus.inTreatment => const Color(0xFFF59E0B), // amber
        ClientStatus.preparingDeparture => const Color(0xFFEC4899), // pink
        ClientStatus.departed => const Color(0xFF64748B), // slate
        ClientStatus.completed => const Color(0xFF10B981), // green
      };

  IconData get icon => switch (this) {
        ClientStatus.awaitingArrival => Icons.flight_land_rounded,
        ClientStatus.met => Icons.handshake_rounded,
        ClientStatus.inHotel => Icons.hotel_rounded,
        ClientStatus.inTreatment => Icons.medical_services_rounded,
        ClientStatus.preparingDeparture => Icons.luggage_rounded,
        ClientStatus.departed => Icons.flight_takeoff_rounded,
        ClientStatus.completed => Icons.check_circle_rounded,
      };
}
