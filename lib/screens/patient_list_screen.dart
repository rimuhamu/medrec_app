import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../models/models.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('All Patients'),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No patients found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.patients.length,
            itemBuilder: (context, index) {
              final patient = provider.patients[index];
              return _PatientCard(
                patient: patient,
                onTap: () => context.push('/patients/${patient.id}'),
                onAppointment: () => _showAppointmentDialog(context, patient),
              );
            },
          );
        },
      ),
    );
  }
}

void _showAppointmentDialog(BuildContext context, Patient patient) {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Parse existing appointment if available
  if (patient.nextAppointment != null) {
    try {
      final existingDate = DateTime.parse(patient.nextAppointment!);
      selectedDate = existingDate;
      selectedTime = TimeOfDay.fromDateTime(existingDate);
    } catch (e) {
      debugPrint('Error parsing existing appointment: $e');
    }
  }

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Set Appointment for ${patient.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patient.nextAppointment != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: ${DateFormat('d MMM y').format(DateTime.parse(patient.nextAppointment!))}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Select Appointment Date',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate != null
                      ? DateFormat('EEEE, d MMMM y').format(selectedDate!)
                      : 'Choose Date',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selectedDate == null || selectedTime == null
                ? null
                : () async {
                    final appointmentDateString =
                        DateFormat('yyyy-MM-dd').format(selectedDate!);

                    final provider = context.read<PatientProvider>();
                    final success = await provider.updatePatientAppointment(
                      patient.id,
                      appointmentDateString,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Appointment scheduled successfully'
                                : 'Failed to schedule appointment',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );

                      if (success) {
                        // Reload the patients list
                        await provider.loadPatients();
                      }
                    }
                  },
            child: const Text('Set Appointment'),
          ),
        ],
      ),
    ),
  );
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback onAppointment;

  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.onAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      patient.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${patient.age} years old',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    patient.phoneNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patient.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (patient.nextAppointment != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Next: ${DateFormat('d MMM y').format(DateTime.parse(patient.nextAppointment!))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAppointment,
                  icon: Icon(
                    patient.nextAppointment != null
                        ? Icons.edit_calendar
                        : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    patient.nextAppointment != null
                        ? 'Update Appointment'
                        : 'Set Appointment',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
