import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.medication),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name ?? 'N/A',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dosage: ${med.dosage ?? 'N/A'}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'Frequency: ${med.frequency ?? 'N/A'}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'Duration: ${med.duration ?? 'N/A'}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('MMM d, y').format(med.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isAdmin) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _showEditMedicationDialog(
                                                context, med),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () =>
                                            _deleteMedication(context, med.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
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

    _showMedicationBottomSheet(
      context: context,
      title: 'Add Medication',
      submitText: 'Add',
      nameController: nameController,
      dosageController: dosageController,
      frequencyController: frequencyController,
      durationController: durationController,
      onSubmit: () async {
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
              content: Text(
                  success ? 'Medication added' : 'Failed to add medication'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showEditMedicationDialog(BuildContext context, dynamic med) {
    final nameController = TextEditingController(text: med.name);
    final dosageController = TextEditingController(text: med.dosage);
    final frequencyController = TextEditingController(text: med.frequency);
    final durationController = TextEditingController(text: med.duration);

    _showMedicationBottomSheet(
      context: context,
      title: 'Edit Medication',
      submitText: 'Save',
      nameController: nameController,
      dosageController: dosageController,
      frequencyController: frequencyController,
      durationController: durationController,
      onSubmit: () async {
        final provider = context.read<PatientProvider>();
        final success = await provider.updateMedication(patientId, med.id, {
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
                  ? 'Medication updated'
                  : 'Failed to update medication'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showMedicationBottomSheet({
    required BuildContext context,
    required String title,
    required String submitText,
    required TextEditingController nameController,
    required TextEditingController dosageController,
    required TextEditingController frequencyController,
    required TextEditingController durationController,
    required VoidCallback onSubmit,
  }) {
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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    onPressed: onSubmit,
                    child: Text(submitText),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: frequencyController,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: 'Duration'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);

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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No medical history',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medical records will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.medicalHistory.length,
                  itemBuilder: (context, index) {
                    final history = provider.medicalHistory[index];
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with edit button
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.medical_information,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Medical History',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Last updated: ${DateFormat('MMM d, y').format(history.updatedAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _showEditHistoryDialog(
                                        context, history),
                                    tooltip: 'Edit Medical History',
                                  ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteMedicalHistory(
                                        context, history.id),
                                    tooltip: 'Delete Medical History',
                                  ),
                              ],
                            ),
                          ),
                          // Content sections
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection(
                                  icon: Icons.medical_services,
                                  iconColor: Colors.blue,
                                  label: 'Medical Conditions',
                                  value: history.medicalConditions ??
                                      'None recorded',
                                ),
                                const SizedBox(height: 16),
                                _buildAllergySection(
                                  allergies: history.allergies,
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.local_hospital,
                                  iconColor: Colors.red,
                                  label: 'Surgeries',
                                  value: history.surgeries ?? 'None recorded',
                                ),
                                const SizedBox(height: 16),
                                _buildSection(
                                  icon: Icons.healing,
                                  iconColor: Colors.green,
                                  label: 'Treatments',
                                  value: history.treatments ?? 'None recorded',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllergySection({List<String>? allergies}) {
    final hasAllergies = allergies != null && allergies.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              size: 20, color: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allergies',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              hasAllergies
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allergies.map((allergy) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            allergy,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const Text(
                      'No known allergies',
                      style: TextStyle(fontSize: 15),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddHistoryDialog(BuildContext context) {
    final conditionsController = TextEditingController();
    final allergiesController = TextEditingController();
    final surgeriesController = TextEditingController();
    final treatmentsController = TextEditingController();

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
                    'Add Medical History',
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

                      final success =
                          await provider.addMedicalHistory(patientId, {
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
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Add'),
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

  void _deleteMedicalHistory(BuildContext context, int historyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medical History'),
        content:
            const Text('Are you sure you want to delete this medical record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final success =
                  await provider.deleteMedicalHistory(patientId, historyId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Medical record deleted'
                        : 'Failed to delete medical record'),
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
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    padding: const EdgeInsets.only(left: 8),
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _showEditTestDialog(context, test),
                                  ),
                                if (isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    padding: const EdgeInsets.only(left: 8),
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _deleteDiagnosticTest(context, test.id),
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

    _showTestBottomSheet(
      context: context,
      title: 'Add Test Result',
      submitText: 'Add',
      titleController: titleController,
      resultController: resultController,
      onSubmit: () async {
        final provider = context.read<PatientProvider>();
        final success = await provider.addDiagnosticTest(patientId, {
          'title': titleController.text,
          'result': resultController.text,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  success ? 'Test result added' : 'Failed to add test result'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showEditTestDialog(BuildContext context, dynamic test) {
    final titleController = TextEditingController(text: test.title);
    final resultController = TextEditingController(text: test.result);

    _showTestBottomSheet(
      context: context,
      title: 'Edit Test Result',
      submitText: 'Save',
      titleController: titleController,
      resultController: resultController,
      onSubmit: () async {
        final provider = context.read<PatientProvider>();
        final success =
            await provider.updateDiagnosticTest(patientId, test.id, {
          'title': titleController.text,
          'result': resultController.text,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Test result updated'
                  : 'Failed to update test result'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
    );
  }

  void _showTestBottomSheet({
    required BuildContext context,
    required String title,
    required String submitText,
    required TextEditingController titleController,
    required TextEditingController resultController,
    required VoidCallback onSubmit,
  }) {
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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton(
                    onPressed: onSubmit,
                    child: Text(submitText),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Test Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resultController,
                    decoration: const InputDecoration(labelText: 'Result'),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDiagnosticTest(BuildContext context, int testId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Result'),
        content:
            const Text('Are you sure you want to delete this test result?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final provider = context.read<PatientProvider>();
              final success =
                  await provider.deleteDiagnosticTest(patientId, testId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Test result deleted'
                        : 'Failed to delete test result'),
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
