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

  List<Patient> get patients => _patients;
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
        _apiService.getMedications(patientId),
        _apiService.getMedicalHistory(patientId),
        _apiService.getDiagnosticTests(patientId),
      ]);

      _medications = results[0] as List<Medication>;
      _medicalHistory = results[1] as List<MedicalHistory>;
      _diagnosticTests = results[2] as List<DiagnosticTestResult>;

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
}
