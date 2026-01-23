import 'package:equatable/equatable.dart';
import 'patient.dart';

/// Represents a user in the medical records system.
///
/// Users can be either administrators or patients. Patient users have
/// an associated [Patient] record linked via [patientId].
class User extends Equatable {
  final int id;
  final String username;
  final String role;
  final int? patientId;
  final Patient? patient;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.patientId,
    this.patient,
  });

  /// Creates a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      patientId: json['patientId'] as int?,
      patient: json['patient'] != null
          ? Patient.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts this [User] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'patientId': patientId,
      'patient': patient?.toJson(),
    };
  }

  /// Returns `true` if this user has admin privileges.
  bool get isAdmin => role == 'admin';

  /// Returns `true` if this user is a patient.
  bool get isPatient => role == 'patient';

  /// Creates a copy of this [User] with the given fields replaced.
  User copyWith({
    int? id,
    String? username,
    String? role,
    int? patientId,
    Patient? patient,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      patientId: patientId ?? this.patientId,
      patient: patient ?? this.patient,
    );
  }

  @override
  List<Object?> get props => [id, username, role, patientId, patient];

  @override
  String toString() {
    return 'User(id: $id, username: $username, role: $role, patientId: $patientId)';
  }
}
