import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/widgets.dart';

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
              final router = GoRouter.of(context);
              await context.read<AuthProvider>().logout();
              if (mounted) router.go('/login');
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PatientProvider>(
        builder: (context, auth, patientProvider, _) {
          if (patientProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading data...');
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(auth, patientProvider),
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

  Widget _buildWelcomeSection(
      AuthProvider auth, PatientProvider patientProvider) {
    final name = auth.isAdmin
        ? auth.user?.username ?? ''
        : auth.user?.patient?.name ??
            patientProvider.currentPatient?.name ??
            '';

    return WelcomeCard(
      name: name,
      isAdmin: auth.isAdmin,
    );
  }

  Widget _buildAdminDashboard(PatientProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'All Patients'),
        const SizedBox(height: 16),
        StatsCard(
          title: 'Total Patients',
          value: provider.patients.length.toString(),
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => context.push('/patients'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.push('/patients/add'),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Patient'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/patients'),
                icon: const Icon(Icons.people),
                label: const Text('View All'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDashboard(AuthProvider auth, PatientProvider provider) {
    final patient = provider.currentPatient ?? auth.user?.patient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (patient?.nextAppointment != null) ...[
          AppointmentCard(
            appointmentDate: DateTime.parse(patient!.nextAppointment!),
          ),
          const SizedBox(height: 16),
        ],
        const SectionHeader(title: 'My Medical Records'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Medications',
                value: provider.medications.length.toString(),
                icon: Icons.medication,
                color: Colors.green,
                onTap: () =>
                    context.push('/patients/${auth.user!.patientId}?tab=0'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'History',
                value: provider.medicalHistory.length.toString(),
                icon: Icons.history,
                color: Colors.blue,
                onTap: () =>
                    context.push('/patients/${auth.user!.patientId}?tab=1'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Test Results',
                value: provider.diagnosticTests.length.toString(),
                icon: Icons.science,
                color: Colors.orange,
                onTap: () =>
                    context.push('/patients/${auth.user!.patientId}?tab=2'),
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
}
