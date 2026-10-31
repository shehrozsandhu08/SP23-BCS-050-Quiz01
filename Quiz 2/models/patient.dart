class Patient {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String bloodGroup;
  final String diagnosis;
  final String medicalHistory;
  final String prescription;
  final String status; // 'Active', 'Critical', 'Recovered', 'Follow-up'
  final String visitDate;
  final String? avatarPath;
  final String createdAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    this.email = '',
    required this.bloodGroup,
    required this.diagnosis,
    this.medicalHistory = '',
    this.prescription = '',
    this.status = 'Active',
    required this.visitDate,
    this.avatarPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'bloodGroup': bloodGroup,
      'diagnosis': diagnosis,
      'medicalHistory': medicalHistory,
      'prescription': prescription,
      'status': status,
      'visitDate': visitDate,
      'avatarPath': avatarPath,
      'createdAt': createdAt,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] ?? 'Male',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      bloodGroup: map['bloodGroup'] ?? 'O+',
      diagnosis: map['diagnosis'] ?? '',
      medicalHistory: map['medicalHistory'] ?? '',
      prescription: map['prescription'] ?? '',
      status: map['status'] ?? 'Active',
      visitDate: map['visitDate'] ?? '',
      avatarPath: map['avatarPath'] as String?,
      createdAt: map['createdAt'] ?? '',
    );
  }

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? bloodGroup,
    String? diagnosis,
    String? medicalHistory,
    String? prescription,
    String? status,
    String? visitDate,
    String? avatarPath,
    String? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      diagnosis: diagnosis ?? this.diagnosis,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      prescription: prescription ?? this.prescription,
      status: status ?? this.status,
      visitDate: visitDate ?? this.visitDate,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
