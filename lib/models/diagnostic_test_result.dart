import 'package:equatable/equatable.dart';

/// Represents a diagnostic test result for a patient.
///
/// Contains the test title and result information.
class DiagnosticTestResult extends Equatable {
  final int id;
  final String? title;
  final String? result;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiagnosticTestResult({
    required this.id,
    this.title,
    this.result,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [DiagnosticTestResult] from a JSON map.
  factory DiagnosticTestResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticTestResult(
      id: json['id'] as int,
      title: json['title'] as String?,
      result: json['result'] as String?,
      patientId: json['patientId'] as int,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  /// Converts this [DiagnosticTestResult] to a JSON map for API requests.
  ///
  /// Note: Only includes fields that are typically updated by the client.
  /// Server-managed fields like [id], [patientId], [createdAt], and [updatedAt] are excluded.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'result': result,
    };
  }

  /// Converts this [DiagnosticTestResult] to a complete JSON map including all fields.
  Map<String, dynamic> toFullJson() {
    return {
      'id': id,
      'title': title,
      'result': result,
      'patientId': patientId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Returns `true` if the test has both a title and a result.
  bool get isComplete => title != null && result != null;

  /// Returns `true` if the test is pending (has title but no result).
  bool get isPending => title != null && result == null;

  /// Creates a copy of this [DiagnosticTestResult] with the given fields replaced.
  DiagnosticTestResult copyWith({
    int? id,
    String? title,
    String? result,
    int? patientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiagnosticTestResult(
      id: id ?? this.id,
      title: title ?? this.title,
      result: result ?? this.result,
      patientId: patientId ?? this.patientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        result,
        patientId,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'DiagnosticTestResult(id: $id, title: $title, isComplete: $isComplete)';
  }
}
