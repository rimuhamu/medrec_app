import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/patient_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;
  final int initialTabIndex;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.initialTabIndex = 0,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
            return const LoadingIndicator(message: 'Loading records...');
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

// ============================================================================
// MEDICATIONS TAB
// ============================================================================

class _MedicationsTab extends StatelessWidget {
  final int patientId;
  final bool isAdmin;

  const _MedicationsTab({required this.patientId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Column(
      children: [
        if (isAdmin) _buildAddButton(context),
        Expanded(
          child: provider.medications.isEmpty
              ? const EmptyState(
                  icon: Icons.medication_outlined,
                  title: 'No medications',
                  subtitle: 'Prescriptions will appear here',
                )
              : _buildMedicationsList(context, provider.medications),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showAddMedicationDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Medication'),
        ),
      ),
    );
  }

  Widget _buildMedicationsList(
      BuildContext context, List<Medication> medications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final med = medications[index];
        return MedicationCard(
          medication: med,
          isAdmin: isAdmin,
          onEdit: () => _showEditMedicationDialog(context, med),
          onDelete: () => _deleteMedication(context, med.id),
        );
      },
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final durationController = TextEditingController();

    _showMedicationSheet(
      context: context,
      title: 'Add Medication',
      submitLabel: 'Add',
      nameController: nameController,
      dosageController: dosageController,
      frequencyController: frequencyController,
      durationController: durationController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        final success = await provider.addMedication(patientId, {
          'name': nameController.text,
          'dosage': dosageController.text,
          'frequency': frequencyController.text,
          'duration': durationController.text,
        });
        return success;
      },
      successMessage: 'Medication added',
      errorMessage: 'Failed to add medication',
    );
  }

  void _showEditMedicationDialog(BuildContext context, Medication med) {
    final nameController = TextEditingController(text: med.name);
    final dosageController = TextEditingController(text: med.dosage);
    final frequencyController = TextEditingController(text: med.frequency);
    final durationController = TextEditingController(text: med.duration);

    _showMedicationSheet(
      context: context,
      title: 'Edit Medication',
      submitLabel: 'Save',
      nameController: nameController,
      dosageController: dosageController,
      frequencyController: frequencyController,
      durationController: durationController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        final success = await provider.updateMedication(patientId, med.id, {
          'name': nameController.text,
          'dosage': dosageController.text,
          'frequency': frequencyController.text,
          'duration': durationController.text,
        });
        return success;
      },
      successMessage: 'Medication updated',
      errorMessage: 'Failed to update medication',
    );
  }

  void _showMedicationSheet({
    required BuildContext context,
    required String title,
    required String submitLabel,
    required TextEditingController nameController,
    required TextEditingController dosageController,
    required TextEditingController frequencyController,
    required TextEditingController durationController,
    required Future<bool> Function(BuildContext) onSubmit,
    required String successMessage,
    required String errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MedicationFormSheet(
        title: title,
        submitLabel: submitLabel,
        nameController: nameController,
        dosageController: dosageController,
        frequencyController: frequencyController,
        durationController: durationController,
        onSubmit: () async {
          final success = await onSubmit(sheetContext);
          if (sheetContext.mounted) {
            Navigator.pop(sheetContext);
            AppSnackBar.showResult(
              sheetContext,
              success: success,
              successMessage: successMessage,
              errorMessage: errorMessage,
            );
          }
        },
      ),
    );
  }

  void _deleteMedication(BuildContext context, int medicationId) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Medication',
      message: 'Are you sure you want to delete this medication?',
      confirmLabel: 'Delete',
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<PatientProvider>();
      final success = await provider.deleteMedication(patientId, medicationId);

      if (context.mounted) {
        AppSnackBar.showResult(
          context,
          success: success,
          successMessage: 'Medication deleted',
          errorMessage: 'Failed to delete medication',
        );
      }
    }
  }
}

/// Card widget for displaying medication information.
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.medication)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name ?? 'N/A',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  _buildDetail('Dosage', medication.dosage),
                  _buildDetail('Frequency', medication.frequency),
                  _buildDetail('Duration', medication.duration),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d, y').format(medication.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
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
  }

  Widget _buildDetail(String label, String? value) {
    return Text(
      '$label: ${value ?? 'N/A'}',
      style: TextStyle(color: Colors.grey[700]),
    );
  }
}

/// Bottom sheet form for adding/editing medications.
class _MedicationFormSheet extends StatelessWidget {
  final String title;
  final String submitLabel;
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;
  final VoidCallback onSubmit;

  const _MedicationFormSheet({
    required this.title,
    required this.submitLabel,
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
    required this.durationController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                BottomSheetFormField(
                  controller: nameController,
                  label: 'Name',
                  icon: Icons.medication,
                ),
                const SizedBox(height: 16),
                BottomSheetFormField(
                  controller: dosageController,
                  label: 'Dosage',
                  hint: 'e.g., 500mg',
                ),
                const SizedBox(height: 16),
                BottomSheetFormField(
                  controller: frequencyController,
                  label: 'Frequency',
                  hint: 'e.g., Twice daily',
                ),
                const SizedBox(height: 16),
                BottomSheetFormField(
                  controller: durationController,
                  label: 'Duration',
                  hint: 'e.g., 7 days',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          FilledButton(
            onPressed: onSubmit,
            child: Text(submitLabel),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MEDICAL HISTORY TAB
// ============================================================================

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
          _buildAddButton(context),
        Expanded(
          child: provider.medicalHistory.isEmpty
              ? const EmptyState(
                  icon: Icons.history_outlined,
                  title: 'No medical history',
                  subtitle: 'Medical records will appear here',
                )
              : _buildHistoryList(context, provider.medicalHistory),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showAddHistoryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Medical History'),
        ),
      ),
    );
  }

  Widget _buildHistoryList(
      BuildContext context, List<MedicalHistory> historyList) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historyList.length,
      itemBuilder: (context, index) {
        final history = historyList[index];
        return MedicalHistoryCard(
          history: history,
          isAdmin: isAdmin,
          onEdit: () => _showEditHistoryDialog(context, history),
          onDelete: () => _deleteHistory(context, history.id),
        );
      },
    );
  }

  void _showAddHistoryDialog(BuildContext context) {
    final conditionsController = TextEditingController();
    final allergiesController = TextEditingController();
    final surgeriesController = TextEditingController();
    final treatmentsController = TextEditingController();

    _showHistorySheet(
      context: context,
      title: 'Add Medical History',
      submitLabel: 'Add',
      conditionsController: conditionsController,
      allergiesController: allergiesController,
      surgeriesController: surgeriesController,
      treatmentsController: treatmentsController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        final allergies = allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        return await provider.addMedicalHistory(patientId, {
          'medicalConditions': conditionsController.text,
          'allergies': allergies,
          'surgeries': surgeriesController.text,
          'treatments': treatmentsController.text,
        });
      },
      successMessage: 'Medical history added',
      errorMessage: 'Failed to add medical history',
    );
  }

  void _showEditHistoryDialog(BuildContext context, MedicalHistory history) {
    final conditionsController =
        TextEditingController(text: history.medicalConditions ?? '');
    final allergiesController =
        TextEditingController(text: history.allergies?.join(', ') ?? '');
    final surgeriesController =
        TextEditingController(text: history.surgeries ?? '');
    final treatmentsController =
        TextEditingController(text: history.treatments ?? '');

    _showHistorySheet(
      context: context,
      title: 'Edit Medical History',
      submitLabel: 'Save',
      conditionsController: conditionsController,
      allergiesController: allergiesController,
      surgeriesController: surgeriesController,
      treatmentsController: treatmentsController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        final allergies = allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        return await provider.updateMedicalHistory(patientId, history.id, {
          'medicalConditions': conditionsController.text,
          'allergies': allergies,
          'surgeries': surgeriesController.text,
          'treatments': treatmentsController.text,
        });
      },
      successMessage: 'Medical history updated',
      errorMessage: 'Failed to update medical history',
    );
  }

  void _showHistorySheet({
    required BuildContext context,
    required String title,
    required String submitLabel,
    required TextEditingController conditionsController,
    required TextEditingController allergiesController,
    required TextEditingController surgeriesController,
    required TextEditingController treatmentsController,
    required Future<bool> Function(BuildContext) onSubmit,
    required String successMessage,
    required String errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MedicalHistoryFormSheet(
        title: title,
        submitLabel: submitLabel,
        conditionsController: conditionsController,
        allergiesController: allergiesController,
        surgeriesController: surgeriesController,
        treatmentsController: treatmentsController,
        onSubmit: () async {
          final success = await onSubmit(sheetContext);
          if (sheetContext.mounted) {
            Navigator.pop(sheetContext);
            AppSnackBar.showResult(
              sheetContext,
              success: success,
              successMessage: successMessage,
              errorMessage: errorMessage,
            );
          }
        },
      ),
    );
  }

  void _deleteHistory(BuildContext context, int historyId) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Medical History',
      message: 'Are you sure you want to delete this medical record?',
      confirmLabel: 'Delete',
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<PatientProvider>();
      final success = await provider.deleteMedicalHistory(patientId, historyId);

      if (context.mounted) {
        AppSnackBar.showResult(
          context,
          success: success,
          successMessage: 'Medical record deleted',
          errorMessage: 'Failed to delete medical record',
        );
      }
    }
  }
}

/// Card widget for displaying medical history.
class MedicalHistoryCard extends StatelessWidget {
  final MedicalHistory history;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicalHistoryCard({
    super.key,
    required this.history,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoCard(
                  icon: Icons.medical_services,
                  iconColor: Colors.blue,
                  label: 'Medical Conditions',
                  value: history.medicalConditions ?? 'None recorded',
                ),
                const SizedBox(height: 16),
                _buildAllergySection(),
                const SizedBox(height: 16),
                InfoCard(
                  icon: Icons.local_hospital,
                  iconColor: Colors.red,
                  label: 'Surgeries',
                  value: history.surgeries ?? 'None recorded',
                ),
                const SizedBox(height: 16),
                InfoCard(
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
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_information, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Last updated: ${DateFormat('MMM d, y').format(history.updatedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit Medical History',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete Medical History',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllergySection() {
    final hasAllergies =
        history.allergies != null && history.allergies!.isNotEmpty;

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
                      children: history.allergies!.map((allergy) {
                        return StatusChip(
                          label: allergy,
                          backgroundColor: Colors.orange.withValues(alpha: 0.1),
                          textColor: Colors.orange[800],
                        );
                      }).toList(),
                    )
                  : const Text('No known allergies',
                      style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet form for adding/editing medical history.
class _MedicalHistoryFormSheet extends StatelessWidget {
  final String title;
  final String submitLabel;
  final TextEditingController conditionsController;
  final TextEditingController allergiesController;
  final TextEditingController surgeriesController;
  final TextEditingController treatmentsController;
  final VoidCallback onSubmit;

  const _MedicalHistoryFormSheet({
    required this.title,
    required this.submitLabel,
    required this.conditionsController,
    required this.allergiesController,
    required this.surgeriesController,
    required this.treatmentsController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                BottomSheetFormField(
                  controller: conditionsController,
                  label: 'Medical Conditions',
                  icon: Icons.medical_information,
                  hint: 'e.g., Type 2 Diabetes, Hypertension',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                BottomSheetFormField(
                  controller: allergiesController,
                  label: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                  hint: 'Separate multiple allergies with commas',
                  helperText: 'e.g., Penicillin, Shellfish, Peanuts',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                BottomSheetFormField(
                  controller: surgeriesController,
                  label: 'Surgeries',
                  icon: Icons.local_hospital,
                  hint: 'Previous surgical procedures',
                  helperText: 'Include dates if known',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                BottomSheetFormField(
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
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
        ],
      ),
    );
  }
}

// ============================================================================
// DIAGNOSTIC TESTS TAB
// ============================================================================

class _DiagnosticTestsTab extends StatelessWidget {
  final int patientId;
  final bool isAdmin;

  const _DiagnosticTestsTab({required this.patientId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Column(
      children: [
        if (isAdmin) _buildAddButton(context),
        Expanded(
          child: provider.diagnosticTests.isEmpty
              ? const EmptyState(
                  icon: Icons.science_outlined,
                  title: 'No test results',
                  subtitle: 'Diagnostic tests will appear here',
                )
              : _buildTestsList(context, provider.diagnosticTests),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showAddTestDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Test Result'),
        ),
      ),
    );
  }

  Widget _buildTestsList(
      BuildContext context, List<DiagnosticTestResult> tests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        return DiagnosticTestCard(
          test: test,
          isAdmin: isAdmin,
          onEdit: () => _showEditTestDialog(context, test),
          onDelete: () => _deleteTest(context, test.id),
        );
      },
    );
  }

  void _showAddTestDialog(BuildContext context) {
    final titleController = TextEditingController();
    final resultController = TextEditingController();

    _showTestSheet(
      context: context,
      title: 'Add Test Result',
      submitLabel: 'Add',
      titleController: titleController,
      resultController: resultController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        return await provider.addDiagnosticTest(patientId, {
          'title': titleController.text,
          'result': resultController.text,
        });
      },
      successMessage: 'Test result added',
      errorMessage: 'Failed to add test result',
    );
  }

  void _showEditTestDialog(BuildContext context, DiagnosticTestResult test) {
    final titleController = TextEditingController(text: test.title);
    final resultController = TextEditingController(text: test.result);

    _showTestSheet(
      context: context,
      title: 'Edit Test Result',
      submitLabel: 'Save',
      titleController: titleController,
      resultController: resultController,
      onSubmit: (ctx) async {
        final provider = ctx.read<PatientProvider>();
        return await provider.updateDiagnosticTest(patientId, test.id, {
          'title': titleController.text,
          'result': resultController.text,
        });
      },
      successMessage: 'Test result updated',
      errorMessage: 'Failed to update test result',
    );
  }

  void _showTestSheet({
    required BuildContext context,
    required String title,
    required String submitLabel,
    required TextEditingController titleController,
    required TextEditingController resultController,
    required Future<bool> Function(BuildContext) onSubmit,
    required String successMessage,
    required String errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _DiagnosticTestFormSheet(
        title: title,
        submitLabel: submitLabel,
        titleController: titleController,
        resultController: resultController,
        onSubmit: () async {
          final success = await onSubmit(sheetContext);
          if (sheetContext.mounted) {
            Navigator.pop(sheetContext);
            AppSnackBar.showResult(
              sheetContext,
              success: success,
              successMessage: successMessage,
              errorMessage: errorMessage,
            );
          }
        },
      ),
    );
  }

  void _deleteTest(BuildContext context, int testId) async {
    final confirm = await ConfirmDialog.show(
      context: context,
      title: 'Delete Test Result',
      message: 'Are you sure you want to delete this test result?',
      confirmLabel: 'Delete',
      isDangerous: true,
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<PatientProvider>();
      final success = await provider.deleteDiagnosticTest(patientId, testId);

      if (context.mounted) {
        AppSnackBar.showResult(
          context,
          success: success,
          successMessage: 'Test result deleted',
          errorMessage: 'Failed to delete test result',
        );
      }
    }
  }
}

/// Card widget for displaying diagnostic test results.
class DiagnosticTestCard extends StatelessWidget {
  final DiagnosticTestResult test;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiagnosticTestCard({
    super.key,
    required this.test,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(test.result ?? 'No result'),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet form for adding/editing diagnostic tests.
class _DiagnosticTestFormSheet extends StatelessWidget {
  final String title;
  final String submitLabel;
  final TextEditingController titleController;
  final TextEditingController resultController;
  final VoidCallback onSubmit;

  const _DiagnosticTestFormSheet({
    required this.title,
    required this.submitLabel,
    required this.titleController,
    required this.resultController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                BottomSheetFormField(
                  controller: titleController,
                  label: 'Test Title',
                  icon: Icons.science,
                ),
                const SizedBox(height: 16),
                BottomSheetFormField(
                  controller: resultController,
                  label: 'Result',
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
        ],
      ),
    );
  }
}
