import 'package:equatable/equatable.dart';

/// Represents a single time slot in the medication schedule.
class ScheduleItem extends Equatable {
  final String timeOfDay;
  final List<String> medicines;

  const ScheduleItem({
    required this.timeOfDay,
    required this.medicines,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      timeOfDay: json['time_of_day'] as String? ?? '',
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'time_of_day': timeOfDay,
        'medicines': medicines,
      };

  @override
  List<Object?> get props => [timeOfDay, medicines];

  @override
  String toString() =>
      'ScheduleItem(timeOfDay: $timeOfDay, medicines: $medicines)';
}

/// Response wrapper for the medication schedule API.
class MedicationScheduleResponse extends Equatable {
  final List<ScheduleItem> schedule;

  const MedicationScheduleResponse({required this.schedule});

  factory MedicationScheduleResponse.fromJson(Map<String, dynamic> json) {
    final scheduleData = json['schedule'];

    if (scheduleData is List) {
      return MedicationScheduleResponse(
        schedule: scheduleData
            .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    // Handle case where schedule might be a string (fallback from API)
    return const MedicationScheduleResponse(schedule: []);
  }

  Map<String, dynamic> toJson() => {
        'schedule': schedule.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [schedule];

  @override
  String toString() => 'MedicationScheduleResponse(schedule: $schedule)';
}
