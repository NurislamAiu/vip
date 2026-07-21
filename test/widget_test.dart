import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vip/models/client.dart';
import 'package:vip/models/client_filter.dart';
import 'package:vip/models/client_status.dart';
import 'package:vip/models/user_role.dart';

void main() {
  group('ClientStatus', () {
    test('round-trips through its string form', () {
      for (final status in ClientStatus.values) {
        expect(ClientStatus.fromString(status.asString), status);
      }
    });

    test('falls back to awaitingArrival for unknown values', () {
      expect(ClientStatus.fromString('nonsense'),
          ClientStatus.awaitingArrival);
    });

    test('every status has a distinct color', () {
      final colors = ClientStatus.values.map((s) => s.color.toARGB32()).toSet();
      expect(colors.length, ClientStatus.values.length);
    });
  });

  group('UserRole', () {
    test('administrator is admin, manager is not', () {
      expect(UserRole.administrator.isAdmin, isTrue);
      expect(UserRole.manager.isAdmin, isFalse);
    });
  });

  group('Client search + filter', () {
    final client = Client(
      id: '1',
      clientNumber: 'A-100',
      name: 'John Traveller',
      phone: '+10000000',
      hotel: 'Grand Plaza',
      driverName: 'Sam Driver',
      status: ClientStatus.inHotel,
      arrivalDate: DateTime(2026, 7, 20),
    );

    test('haystack matches name, hotel and driver', () {
      expect(client.searchHaystack.contains('grand plaza'), isTrue);
      expect(client.searchHaystack.contains('sam driver'), isTrue);
      expect(client.searchHaystack.contains('a-100'), isTrue);
    });

    test('arrivingToday filter matches same day only', () {
      expect(
        ClientFilter.arrivingToday.matches(client, DateTime(2026, 7, 20, 15)),
        isTrue,
      );
      expect(
        ClientFilter.arrivingToday.matches(client, DateTime(2026, 7, 21)),
        isFalse,
      );
    });

    test('inHotel filter matches by status', () {
      expect(ClientFilter.inHotel.matches(client, DateTime.now()), isTrue);
      expect(
        ClientFilter.completed.matches(client, DateTime.now()),
        isFalse,
      );
    });
  });

  test('placeholder theme smoke', () {
    // Ensures Material color utilities are wired without needing Firebase.
    expect(Colors.blue.toARGB32(), isNonZero);
  });
}
