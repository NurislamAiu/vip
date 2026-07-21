import 'package:cloud_firestore/cloud_firestore.dart';

import 'client_status.dart';

/// A VIP client of the clinic, stored in the `clients` collection.
///
/// Calendar dates (arrival / appointment / departure) are stored as Firestore
/// [Timestamp]s so they can be range-queried. Times of day are stored as plain
/// `HH:mm` strings — they carry no timezone meaning on their own.
class Client {
  const Client({
    required this.id,
    required this.clientNumber,
    required this.name,
    required this.phone,
    this.country = '',
    this.city = '',
    this.arrivalDate,
    this.arrivalTime = '',
    this.arrivalFlight = '',
    this.hotel = '',
    this.doctorName = '',
    this.doctorAppointmentDate,
    this.doctorAppointmentTime = '',
    this.departureDate,
    this.departureTime = '',
    this.departureFlight = '',
    this.driverName = '',
    this.driverPhone = '',
    this.status = ClientStatus.awaitingArrival,
    this.notes = '',
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientNumber;
  final String name;
  final String phone;
  final String country;
  final String city;
  final DateTime? arrivalDate;
  final String arrivalTime;
  final String arrivalFlight;
  final String hotel;
  final String doctorName;
  final DateTime? doctorAppointmentDate;
  final String doctorAppointmentTime;
  final DateTime? departureDate;
  final String departureTime;
  final String departureFlight;
  final String driverName;
  final String driverPhone;
  final ClientStatus status;
  final String notes;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    DateTime? toDate(dynamic value) => (value as Timestamp?)?.toDate();

    return Client(
      id: id,
      clientNumber: (map['clientNumber'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      country: (map['country'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      arrivalDate: toDate(map['arrivalDate']),
      arrivalTime: (map['arrivalTime'] ?? '') as String,
      arrivalFlight: (map['arrivalFlight'] ?? '') as String,
      hotel: (map['hotel'] ?? '') as String,
      doctorName: (map['doctorName'] ?? '') as String,
      doctorAppointmentDate: toDate(map['doctorAppointmentDate']),
      doctorAppointmentTime: (map['doctorAppointmentTime'] ?? '') as String,
      departureDate: toDate(map['departureDate']),
      departureTime: (map['departureTime'] ?? '') as String,
      departureFlight: (map['departureFlight'] ?? '') as String,
      driverName: (map['driverName'] ?? '') as String,
      driverPhone: (map['driverPhone'] ?? '') as String,
      status: ClientStatus.fromString(map['status'] as String?),
      notes: (map['notes'] ?? '') as String,
      createdBy: (map['createdBy'] ?? '') as String,
      createdAt: toDate(map['createdAt']),
      updatedAt: toDate(map['updatedAt']),
    );
  }

  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Client.fromMap(doc.id, doc.data() ?? const {});
  }

  /// Serializes the editable fields. Server timestamps and `createdBy` are
  /// handled by the repository, not here.
  Map<String, dynamic> toMap() {
    Timestamp? ts(DateTime? date) =>
        date == null ? null : Timestamp.fromDate(date);

    return {
      'clientNumber': clientNumber,
      'name': name,
      'phone': phone,
      'country': country,
      'city': city,
      'arrivalDate': ts(arrivalDate),
      'arrivalTime': arrivalTime,
      'arrivalFlight': arrivalFlight,
      'hotel': hotel,
      'doctorName': doctorName,
      'doctorAppointmentDate': ts(doctorAppointmentDate),
      'doctorAppointmentTime': doctorAppointmentTime,
      'departureDate': ts(departureDate),
      'departureTime': departureTime,
      'departureFlight': departureFlight,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': status.asString,
      'notes': notes,
    };
  }

  /// Lower-cased haystack for fast in-memory search across the searchable
  /// fields (name, phone, client number, hotel, driver, status).
  String get searchHaystack => [
        name,
        phone,
        clientNumber,
        hotel,
        driverName,
        status.label,
      ].join(' ').toLowerCase();

  Client copyWith({
    String? clientNumber,
    String? name,
    String? phone,
    String? country,
    String? city,
    DateTime? arrivalDate,
    String? arrivalTime,
    String? arrivalFlight,
    String? hotel,
    String? doctorName,
    DateTime? doctorAppointmentDate,
    String? doctorAppointmentTime,
    DateTime? departureDate,
    String? departureTime,
    String? departureFlight,
    String? driverName,
    String? driverPhone,
    ClientStatus? status,
    String? notes,
  }) {
    return Client(
      id: id,
      clientNumber: clientNumber ?? this.clientNumber,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      city: city ?? this.city,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      arrivalFlight: arrivalFlight ?? this.arrivalFlight,
      hotel: hotel ?? this.hotel,
      doctorName: doctorName ?? this.doctorName,
      doctorAppointmentDate:
          doctorAppointmentDate ?? this.doctorAppointmentDate,
      doctorAppointmentTime:
          doctorAppointmentTime ?? this.doctorAppointmentTime,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      departureFlight: departureFlight ?? this.departureFlight,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
