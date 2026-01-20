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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMM d, y').format(med.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                padding: const EdgeInsets.only(left: 8),
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteMedication(
                                  context,
                                  med.id,
                                ),
                              ),
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
                            if (isAdmin)
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showEditHistoryDialog(context, history),
                                  tooltip: 'Edit Medical History',
                                ),
                              ),
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

  void _showEditHistoryDialog(BuildContext context, dynamic history) {
    final conditionsController =
        TextEditingController(text: history.medicalConditions ?? '');
    final allergiesController =
        TextEditingController(text: history.allergies?.join(', ') ?? '');
    final surgeriesController =
        TextEditingController(text: history.surgeries ?? '');
    final treatmentsController =
        TextEditingController(text: history.treatments ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Edit Medical History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final provider = context.read<PatientProvider>();
                      final allergies = allergiesController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      final success = await provider
                          .updateMedicalHistory(patientId, history.id, {
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
                                ? 'Medical history updated'
                                : 'Failed to update medical history'),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  _buildFormField(
                    controller: conditionsController,
                    label: 'Medical Conditions',
                    icon: Icons.medical_information,
                    hint: 'e.g., Type 2 Diabetes, Hypertension',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: allergiesController,
                    label: 'Allergies',
                    icon: Icons.warning_amber_rounded,
                    hint: 'Separate multiple allergies with commas',
                    helperText: 'e.g., Penicillin, Shellfish, Peanuts',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: surgeriesController,
                    label: 'Surgeries',
                    icon: Icons.local_hospital,
                    hint: 'Previous surgical procedures',
                    helperText: 'Include dates if known',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    controller: treatmentsController,
                    label: 'Treatments',
                    icon: Icons.healing,
                    hint: 'Current or ongoing treatments',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helperText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
          ),
        ),
      ],
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
