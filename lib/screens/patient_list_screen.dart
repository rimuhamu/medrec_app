import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _filterPatients(List<Patient> patients) {
    if (_searchQuery.isEmpty) {
      return patients;
    }

    final query = _searchQuery.toLowerCase();
    return patients.where((patient) {
      return patient.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('All Patients'),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingIndicator(message: 'Loading patients...');
          }

          final filteredPatients = _filterPatients(provider.patients);

          return Column(
            children: [
              _buildSearchBar(),
              if (_searchQuery.isNotEmpty)
                _buildResultsCount(filteredPatients.length),
              const SizedBox(height: 8),
              Expanded(
                child: filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : _buildPatientList(filteredPatients),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SearchTextField(
        controller: _searchController,
        hintText: 'Search by patient name...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = '';
          });
        },
        showClearButton: _searchQuery.isNotEmpty,
      ),
    );
  }

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$count result${count != 1 ? 's' : ''} found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return SearchEmptyState(
        searchQuery: _searchQuery,
        suggestion: 'Try a different name',
      );
    }

    return const EmptyState(
      icon: Icons.people_outline,
      title: 'No patients available',
      subtitle: 'Add your first patient to get started',
    );
  }

  Widget _buildPatientList(List<Patient> patients) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientCard(
          patient: patient,
          searchQuery: _searchQuery,
          onTap: () => context.push('/patients/${patient.id}'),
          onAppointment: () => _showAppointmentDialog(context, patient),
        );
      },
    );
  }

  void _showAppointmentDialog(BuildContext context, Patient patient) {
    DateTime? selectedDate;

    if (patient.nextAppointment != null) {
      try {
        final existingDate = DateTime.parse(patient.nextAppointment!);
        selectedDate = existingDate;
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
              onPressed: selectedDate == null
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

                        AppSnackBar.showResult(
                          dialogContext,
                          success: success,
                          successMessage: 'Appointment scheduled successfully',
                          errorMessage: 'Failed to schedule appointment',
                        );

                        if (success) {
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
}

/// A card widget for displaying patient information in a list.
class PatientCard extends StatelessWidget {
  final Patient patient;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onAppointment;

  const PatientCard({
    super.key,
    required this.patient,
    required this.searchQuery,
    required this.onTap,
    required this.onAppointment,
  });

  TextSpan _highlightMatch(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return TextSpan(text: text);
    }

    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: text.substring(index + query.length)),
      ],
    );
  }

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
              _buildHeader(context),
              const Divider(height: 24),
              _buildContactInfo(context),
              const SizedBox(height: 12),
              if (patient.nextAppointment != null) ...[
                AppointmentBadge(
                  appointmentDate: DateTime.parse(patient.nextAppointment!),
                ),
                const SizedBox(height: 8),
              ],
              _buildAppointmentButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        UserAvatar(name: patient.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  children: [
                    _highlightMatch(patient.name, searchQuery),
                  ],
                ),
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
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildAppointmentButton() {
    return SizedBox(
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
    );
  }
}
