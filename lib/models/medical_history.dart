import 'package:equatable/equatable.dart';

/// Represents a patient's medical history record.
///
/// Contains information about medical conditions, allergies,
/// surgeries, and treatments.
class MedicalHistory extends Equatable {
  final int id;
  final String? medicalConditions;
  final List<String>? allergies;
  final String? surgeries;
  final String? treatments;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalHistory({
    required this.id,
    this.medicalConditions,
    this.allergies,
    this.surgeries,
    this.treatments,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [MedicalHistory] from a JSON map.
  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['id'] as int,
      medicalConditions: json['medicalConditions'] as String?,
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'] as List)
          : null,
      surgeries: json['surgeries'] as String?,
      treatments: json['treatments'] as String?,
      patientId: json['patientId'] as int,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  /// Converts this [MedicalHistory] to a JSON map for API requests.
  ///
  /// Note: Only includes fields that are typically updated by the client.
  /// Server-managed fields like [id], [patientId], [createdAt], and [updatedAt] are excluded.
  Map<String, dynamic> toJson() {
    return {
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'surgeries': surgeries,
      'treatments': treatments,
    };
  }

  /// Converts this [MedicalHistory] to a complete JSON map including all fields.
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'surgeries': surgeries,
      'treatments': treatments,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns `true` if the patient has any recorded allergies.
  bool get hasAllergies => allergies != null && allergies!.isNotEmpty;

  /// Returns the number of recorded allergies.
  int get allergyCount => allergies?.length ?? 0;

  /// Returns `true` if medical history has any recorded information.
  bool get hasAnyRecords =>
      medicalConditions != null ||
      hasAllergies ||
      surgeries != null ||
      treatments != null;

  /// Creates a copy of this [MedicalHistory] with the given fields replaced.
  MedicalHistory copyWith({
    int? id,
    String? medicalConditions,
    List<String>? allergies,
    String? surgeries,
    String? treatments,
    int? patientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalHistory(
      id: id ?? this.id,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      surgeries: surgeries ?? this.surgeries,
      treatments: treatments ?? this.treatments,
      patientId: patientId ?? this.patientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        medicalConditions,
        allergies,
        surgeries,
        treatments,
        patientId,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'MedicalHistory(id: $id, patientId: $patientId, hasAllergies: $hasAllergies)';
  }
}
