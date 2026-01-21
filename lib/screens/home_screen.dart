import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final patientProvider = context.read<PatientProvider>();

    if (auth.isAdmin) {
      await patientProvider.loadPatients();
    } else if (auth.user?.patientId != null) {
      await patientProvider.loadPatientData(auth.user!.patientId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedRec'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PatientProvider>(
        builder: (context, auth, patientProvider, _) {
          if (patientProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(auth),
                  const SizedBox(height: 24),
                  if (auth.isAdmin) ...[
                    _buildAdminDashboard(patientProvider),
                  ] else ...[
                    _buildUserDashboard(auth, patientProvider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(AuthProvider auth) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                auth.isAdmin ? Icons.admin_panel_settings : Icons.person,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    auth.isAdmin
                        ? auth.user?.username ?? ''
                        : auth.user?.patient?.name ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Chip(
                    label: Text(
                      auth.isAdmin ? 'Administrator' : 'Patient',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor:
                        auth.isAdmin ? Colors.purple[100] : Colors.blue[100],
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(PatientProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Patients',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/patients'),
            icon: const Icon(Icons.people),
            label: const Text('View All Patients'),
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsCard(
          'Total Patients',
          provider.patients.length.toString(),
          Icons.people,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildUserDashboard(AuthProvider auth, PatientProvider provider) {
    final patient = auth.user?.patient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (patient?.nextAppointment != null)
          _buildAppointmentReminderCard(patient!),
        if (patient?.nextAppointment != null) const SizedBox(height: 16),
        Text(
          'My Medical Records',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                'Medications',
                provider.medications.length.toString(),
                Icons.medication,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatsCard(
                'Test Results',
                provider.diagnosticTests.length.toString(),
                Icons.science,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (auth.user?.patientId != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push('/patients/${auth.user!.patientId}'),
              icon: const Icon(Icons.visibility),
              label: const Text('View Complete Records'),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentReminderCard(Patient patient) {
    final appointmentDate = DateTime.parse(patient.nextAppointment!);
    final now = DateTime.now();
    final daysUntil = appointmentDate.difference(now).inDays;

    const cardColor = Colors.teal;
    IconData icon;
    String message;

    if (daysUntil < 0) {
      icon = Icons.event_busy;
      message = 'Past appointment';
    } else if (daysUntil == 0) {
      icon = Icons.event_available;
      message = 'Today!';
    } else if (daysUntil == 1) {
      icon = Icons.event;
      message = 'Tomorrow';
    } else if (daysUntil <= 7) {
      icon = Icons.event;
      message = 'In $daysUntil days';
    } else {
      icon = Icons.event;
      message = 'In $daysUntil days';
    }

    return Card(
      color: cardColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cardColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      message,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
