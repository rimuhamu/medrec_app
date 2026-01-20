import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  final storage = const FlutterSecureStorage();
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await deleteToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<String?> getToken() async => await storage.read(key: 'auth_token');
  Future<void> saveToken(String token) async =>
      await storage.write(key: 'auth_token', value: token);
  Future<void> deleteToken() async => await storage.delete(key: 'auth_token');

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data is Map) {
      return e.response?.data['message'] ?? e.message ?? 'Unknown error';
    }
    return e.message ?? 'Connection error';
  }

  // Auth
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required Map<String, dynamic> patientData,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'user': {'username': username, 'password': password},
        'patient': patientData,
      });
      return res.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return res.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<User> getProfile() async {
    try {
      final res = await _dio.get('/auth/profile');
      return User.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Patients
  Future<List<Patient>> getPatients() async {
    try {
      final res = await _dio.get('/patients');
      return (res.data as List).map((json) => Patient.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Patient> getPatient(int id) async {
    try {
      final res = await _dio.get('/patients/$id');
      return Patient.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Medications
  Future<List<Medication>> getMedications(int patientId) async {
    try {
      final res = await _dio.get('/patients/$patientId/medications');
      return (res.data as List)
          .map((json) => Medication.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Medication> createMedication(
      int patientId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/patients/$patientId/medications',
        data: data,
      );
      return Medication.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<void> deleteMedication(int patientId, int id) async {
    try {
      await _dio.delete('/patients/$patientId/medications/$id');
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Medical History
  Future<List<MedicalHistory>> getMedicalHistory(int patientId) async {
    try {
      final res = await _dio.get('/patients/$patientId/medical-history');
      return (res.data as List)
          .map((json) => MedicalHistory.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<MedicalHistory> createMedicalHistory(
      int patientId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/patients/$patientId/medical-history',
        data: data,
      );
      return MedicalHistory.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<MedicalHistory> updateMedicalHistory(
      int patientId, int historyId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(
        '/patients/$patientId/medical-history/$historyId',
        data: data,
      );
      return MedicalHistory.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  // Diagnostic Test Results
  Future<List<DiagnosticTestResult>> getDiagnosticTests(int patientId) async {
    try {
      final res =
          await _dio.get('/patients/$patientId/diagnostic-test-results');
      return (res.data as List)
          .map((json) => DiagnosticTestResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<DiagnosticTestResult> createDiagnosticTest(
      int patientId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/patients/$patientId/diagnostic-test-results',
        data: data,
      );
      return DiagnosticTestResult.fromJson(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }
}
