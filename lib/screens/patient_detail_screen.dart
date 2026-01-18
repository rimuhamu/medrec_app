import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/patient_provider.dart';
import '../providers/auth_provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientProvider>().loadPatientData(widget.patientId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Medications', icon: Icon(Icons.medication)),
            Tab(text: 'History', icon: Icon(Icons.history)),
            Tab(text: 'Tests', icon: Icon(Icons.science)),
          ],
        ),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _MedicationsTab(
                patientId: widget.patientId,
                isAdmin: isAdmin,
              ),
              _MedicalHistoryTab(
                patientId: widget.patientId,
                isAdmin: isAdmin,
              ),
              _DiagnosticTestsTab(
                patientId: widget.patientId,
                isAdmin: isAdmin,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  final int patientId;
  final bool isAdmin;

  const _MedicationsTab({required this.patientId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddMedicationDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
              ),
            ),
          ),
        Expanded(
          child: provider.medications.isEmpty
              ? const Center(child: Text('No medications'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.medications.length,
                  itemBuilder: (context, index) {
                    final med = provider.medications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.medication),
                        ),
                        title: Text(med.name ?? 'N/A'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dosage: ${med.dosage ?? 'N/A'}'),
                            Text('Frequency: ${med.frequency ?? 'N/A'}'),
                            Text('Duration: ${med.duration ?? 'N/A'}'),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteMedication(
                                  context,
                                  med.id,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
              ),
              TextField(
                controller: frequencyController,
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final success = await provider.addMedication(patientId, {
                'name': nameController.text,
                'dosage': dosageController.text,
                'frequency': frequencyController.text,
                'duration': durationController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Medication added'
                        : 'Failed to add medication'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteMedication(BuildContext context, int medicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final success =
                  await provider.deleteMedication(patientId, medicationId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Medication deleted'
                        : 'Failed to delete medication'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MedicalHistoryTab extends StatelessWidget {
  final int patientId;
  final bool isAdmin;

  const _MedicalHistoryTab({required this.patientId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Column(
      children: [
        if (isAdmin && provider.medicalHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddHistoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Medical History'),
              ),
            ),
          ),
        Expanded(
          child: provider.medicalHistory.isEmpty
              ? const Center(child: Text('No medical history'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.medicalHistory.length,
                  itemBuilder: (context, index) {
                    final history = provider.medicalHistory[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Conditions',
                                history.medicalConditions ?? 'N/A'),
                            const SizedBox(height: 12),
                            _buildInfoRow('Allergies',
                                history.allergies?.join(', ') ?? 'None'),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'Surgeries', history.surgeries ?? 'None'),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                'Treatments', history.treatments ?? 'N/A'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  void _showAddHistoryDialog(BuildContext context) {
    final conditionsController = TextEditingController();
    final allergiesController = TextEditingController();
    final surgeriesController = TextEditingController();
    final treatmentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medical History'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conditionsController,
                decoration:
                    const InputDecoration(labelText: 'Medical Conditions'),
              ),
              TextField(
                controller: allergiesController,
                decoration: const InputDecoration(
                    labelText: 'Allergies (comma-separated)'),
              ),
              TextField(
                controller: surgeriesController,
                decoration: const InputDecoration(labelText: 'Surgeries'),
              ),
              TextField(
                controller: treatmentsController,
                decoration: const InputDecoration(labelText: 'Treatments'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final allergies = allergiesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              final success = await provider.addMedicalHistory(patientId, {
                'medicalConditions': conditionsController.text,
                'allergies': allergies,
                'surgeries': surgeriesController.text,
                'treatments': treatmentsController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Medical history added'
                        : 'Failed to add medical history'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticTestsTab extends StatelessWidget {
  final int patientId;
  final bool isAdmin;

  const _DiagnosticTestsTab({required this.patientId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Column(
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddTestDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Test Result'),
              ),
            ),
          ),
        Expanded(
          child: provider.diagnosticTests.isEmpty
              ? const Center(child: Text('No test results'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.diagnosticTests.length,
                  itemBuilder: (context, index) {
                    final test = provider.diagnosticTests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    test.title ?? 'Test Result',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, y').format(test.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(test.result ?? 'No result'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddTestDialog(BuildContext context) {
    final titleController = TextEditingController();
    final resultController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Test Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Test Title'),
            ),
            TextField(
              controller: resultController,
              decoration: const InputDecoration(labelText: 'Result'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final success = await provider.addDiagnosticTest(patientId, {
                'title': titleController.text,
                'result': resultController.text,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Test result added'
                        : 'Failed to add test result'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
