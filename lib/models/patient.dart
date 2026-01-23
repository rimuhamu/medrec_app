import 'package:equatable/equatable.dart';

/// Represents a patient in the medical records system.
///
/// Contains personal information and appointment details for a patient.
class Patient extends Equatable {
  final int id;
  final String name;
  final int age;
  final String address;
  final String phoneNumber;
  final String? nextAppointment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.address,
    required this.phoneNumber,
    this.nextAppointment,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Patient] from a JSON map.
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      name: json['name'] as String,
      age: json['age'] as int,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String,
      nextAppointment: json['nextAppointment'] as String?,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  /// Converts this [Patient] to a JSON map for API requests.
  ///
  /// Note: Only includes fields that are typically updated by the client.
  /// Server-managed fields like [id], [createdAt], and [updatedAt] are excluded.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'address': address,
      'phoneNumber': phoneNumber,
      'nextAppointment': nextAppointment,
    };
  }

  /// Converts this [Patient] to a complete JSON map including all fields.
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'address': address,
      'phoneNumber': phoneNumber,
      'nextAppointment': nextAppointment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns `true` if the patient has an upcoming appointment.
  bool get hasUpcomingAppointment => nextAppointment != null;

  /// Parses the [nextAppointment] string to a [DateTime].
  /// Returns `null` if [nextAppointment] is null or cannot be parsed.
  DateTime? get nextAppointmentDate {
    if (nextAppointment == null) return null;
    try {
      return DateTime.parse(nextAppointment!);
    } catch (_) {
      return null;
    }
  }

  /// Creates a copy of this [Patient] with the given fields replaced.
  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? address,
    String? phoneNumber,
    String? nextAppointment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nextAppointment: nextAppointment ?? this.nextAppointment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        address,
        phoneNumber,
        nextAppointment,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, age: $age, phoneNumber: $phoneNumber)';
  }
}
