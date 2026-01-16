class User {
  final int id;
  final String username;
  final String role;
  final int? patientId;
  final Patient? patient;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.patientId,
    this.patient,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
      patientId: json['patientId'],
      patient:
          json['patient'] != null ? Patient.fromJson(json['patient']) : null,
    );
  }

  bool get isAdmin => role == 'admin';
}

class Patient {
  final int id;
  final String name;
  final int age;
  final String address;
  final String phoneNumber;
  final String? nextAppointment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.address,
    required this.phoneNumber,
    this.nextAppointment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      nextAppointment: json['nextAppointment'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'address': address,
      'phoneNumber': phoneNumber,
      'nextAppointment': nextAppointment,
    };
  }
}

class Medication {
  final int id;
  final String? name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    this.name,
    this.dosage,
    this.frequency,
    this.duration,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
      patientId: json['patientId'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }
}

class MedicalHistory {
  final int id;
  final String? medicalConditions;
  final List<String>? allergies;
  final String? surgeries;
  final String? treatments;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalHistory({
    required this.id,
    this.medicalConditions,
    this.allergies,
    this.surgeries,
    this.treatments,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['id'],
      medicalConditions: json['medicalConditions'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      surgeries: json['surgeries'],
      treatments: json['treatments'],
      patientId: json['patientId'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'surgeries': surgeries,
      'treatments': treatments,
    };
  }
}

class DiagnosticTestResult {
  final int id;
  final String? title;
  final String? result;
  final int patientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiagnosticTestResult({
    required this.id,
    this.title,
    this.result,
    required this.patientId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiagnosticTestResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticTestResult(
      id: json['id'],
      title: json['title'],
      result: json['result'],
      patientId: json['patientId'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'result': result,
    };
  }
}
