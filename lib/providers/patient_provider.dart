import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PatientProvider extends ChangeNotifier {
  final ApiService _apiService;

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
