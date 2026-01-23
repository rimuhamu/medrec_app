import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A card displaying appointment information with reminder styling.
class AppointmentCard extends StatelessWidget {
  final DateTime appointmentDate;
  final String? patientName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final Color accentColor;

  const AppointmentCard({
    super.key,
    required this.appointmentDate,
    this.patientName,
    this.onTap,
    this.onEdit,
    this.accentColor = Colors.teal,
  });

  String get _reminderMessage {
    final now = DateTime.now();
    final daysUntil = appointmentDate.difference(now).inDays;

    if (daysUntil < 0) {
      return 'Past appointment';
    } else if (daysUntil == 0) {
      return 'Today!';
    } else if (daysUntil == 1) {
      return 'Tomorrow';
    } else {
      return 'In $daysUntil days';
    }
  }

  IconData get _reminderIcon {
    final now = DateTime.now();
    final daysUntil = appointmentDate.difference(now).inDays;

    if (daysUntil < 0) {
      return Icons.event_busy;
    } else if (daysUntil == 0) {
      return Icons.event_available;
    } else {
      return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accentColor.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_reminderIcon, color: accentColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (patientName != null) ...[
                      Text(
                        patientName!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      'Next Appointment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, d MMMM y').format(appointmentDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _reminderMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_calendar),
                  tooltip: 'Edit appointment',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A badge showing upcoming appointment date.
class AppointmentBadge extends StatelessWidget {
  final DateTime appointmentDate;
  final Color? backgroundColor;
  final Color? textColor;

  const AppointmentBadge({
    super.key,
    required this.appointmentDate,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: textColor ?? Colors.blue[700],
          ),
          const SizedBox(width: 6),
          Text(
            'Next: ${DateFormat('d MMM y').format(appointmentDate)}',
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
