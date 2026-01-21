import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class PatientProvider extends ChangeNotifier {
  final ApiService _apiService;
  final _notificationService = NotificationService();

  List<Patient> _patients = [];
  List<Medication> _medications = [];
  List<MedicalHistory> _medicalHistory = [];
  List<DiagnosticTestResult> _diagnosticTests = [];

  bool _isLoading = false;
  String? _error;

  PatientProvider(this._apiService);

  Patient? _currentPatient;

  List<Patient> get patients => _patients;
  Patient? get currentPatient => _currentPatient;
  List<Medication> get medications => _medications;
  List<MedicalHistory> get medicalHistory => _medicalHistory;
  List<DiagnosticTestResult> get diagnosticTests => _diagnosticTests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _apiService.getPatients();

      // Schedule notifications for upcoming appointments
      for (final patient in _patients) {
        if (patient.nextAppointment != null) {
          await _scheduleAppointmentNotification(patient);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientData(int patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getPatient(patientId),
        _apiService.getMedications(patientId),
        _apiService.getMedicalHistory(patientId),
        _apiService.getDiagnosticTests(patientId),
      ]);

      _currentPatient = results[0] as Patient;
      _medications = results[1] as List<Medication>;
      _medicalHistory = results[2] as List<MedicalHistory>;
      _diagnosticTests = results[3] as List<DiagnosticTestResult>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(Map<String, dynamic> data) async {
    _error = null;
    try {
      final patient = await _apiService.createPatient(data);
      _patients.add(patient);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPatientUser({
    required String username,
    required String password,
    required Map<String, dynamic> patientData,
  }) async {
    _error = null;
    try {
      await _apiService.register(
        username: username,
        password: password,
        patientData: patientData,
      );
      await loadPatients();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> _scheduleAppointmentNotification(Patient patient) async {
    try {
      final appointmentDate = DateTime.parse(patient.nextAppointment!);
      await _notificationService.scheduleAppointmentNotification(
        id: patient.id,
        patientName: patient.name,
        appointmentDate: appointmentDate,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<bool> updatePatientAppointment(
      int patientId, String appointmentDate) async {
    try {
      final updatedPatient = await _apiService
          .updatePatient(patientId, {'nextAppointment': appointmentDate});

      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        _patients[index] = updatedPatient;
      }

      if (updatedPatient.nextAppointment != null) {
        await _scheduleAppointmentNotification(updatedPatient);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePatient(int patientId) async {
    try {
      await _apiService.deletePatient(patientId);
      _patients.removeWhere((p) => p.id == patientId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMedication(int patientId, Map<String, dynamic> data) async {
    try {
      final med = await _apiService.createMedication(patientId, data);
      _medications.add(med);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedication(
      int patientId, int medicationId, Map<String, dynamic> data) async {
    try {
      final updated =
          await _apiService.updateMedication(patientId, medicationId, data);
      final index = _medications.indexWhere((m) => m.id == medicationId);
      if (index != -1) {
        _medications[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedication(int patientId, int medicationId) async {
    try {
      await _apiService.deleteMedication(patientId, medicationId);
      _medications.removeWhere((m) => m.id == medicationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMedicalHistory(
      int patientId, Map<String, dynamic> data) async {
    try {
      final history = await _apiService.createMedicalHistory(patientId, data);
      _medicalHistory.add(history);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicalHistory(
      int patientId, int historyId, Map<String, dynamic> data) async {
    try {
      final updated =
          await _apiService.updateMedicalHistory(patientId, historyId, data);
      final index = _medicalHistory.indexWhere((h) => h.id == historyId);
      if (index != -1) {
        _medicalHistory[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicalHistory(int patientId, int historyId) async {
    try {
      await _apiService.deleteMedicalHistory(patientId, historyId);
      _medicalHistory.removeWhere((h) => h.id == historyId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDiagnosticTest(
      int patientId, Map<String, dynamic> data) async {
    try {
      final test = await _apiService.createDiagnosticTest(patientId, data);
      _diagnosticTests.add(test);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDiagnosticTest(
      int patientId, int testId, Map<String, dynamic> data) async {
    try {
      final updated =
          await _apiService.updateDiagnosticTest(patientId, testId, data);
      final index = _diagnosticTests.indexWhere((t) => t.id == testId);
      if (index != -1) {
        _diagnosticTests[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDiagnosticTest(int patientId, int testId) async {
    try {
      await _apiService.deleteDiagnosticTest(patientId, testId);
      _diagnosticTests.removeWhere((t) => t.id == testId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
