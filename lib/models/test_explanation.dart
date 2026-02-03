import 'package:equatable/equatable.dart';

/// Response model for the diagnostic test explanation API.
class TestExplanation extends Equatable {
  final String originalResult;
  final String explanation;

  const TestExplanation({
    required this.originalResult,
    required this.explanation,
  });

  factory TestExplanation.fromJson(Map<String, dynamic> json) {
    return TestExplanation(
      originalResult: json['original_result'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'original_result': originalResult,
        'explanation': explanation,
      };

  @override
  List<Object?> get props => [originalResult, explanation];

  @override
  String toString() =>
      'TestExplanation(originalResult: $originalResult, explanation: $explanation)';
}
