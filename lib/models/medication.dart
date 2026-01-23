import 'package:equatable/equatable.dart';

/// Represents a medication prescribed to a patient.
///
/// Contains details about the medication including dosage, frequency,
/// and duration of the prescription.
class Medication extends Equatable {
  final int id;
  final String? name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    this.name,
    this.dosage,
    this.frequency,
    this.duration,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Medication] from a JSON map.
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int,
      name: json['name'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      patientId: json['patientId'] as int,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  /// Converts this [Medication] to a JSON map for API requests.
  ///
  /// Note: Only includes fields that are typically updated by the client.
  /// Server-managed fields like [id], [patientId], [createdAt], and [updatedAt] are excluded.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }

  /// Converts this [Medication] to a complete JSON map including all fields.
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns `true` if the medication has complete prescription details.
  bool get hasCompleteDetails =>
      name != null && dosage != null && frequency != null;

  /// Returns a formatted string describing the prescription.
  String get prescriptionSummary {
    final parts = <String>[];
    if (name != null) parts.add(name!);
    if (dosage != null) parts.add(dosage!);
    if (frequency != null) parts.add(frequency!);
    return parts.join(' - ');
  }

  /// Creates a copy of this [Medication] with the given fields replaced.
  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    int? patientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      patientId: patientId ?? this.patientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dosage,
        frequency,
        duration,
        patientId,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, frequency: $frequency)';
  }
}
