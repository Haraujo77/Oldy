class Patient {
  final String id;
  final String fullName;
  final String? nickname;
  final String? photoUrl;
  final DateTime dateOfBirth;
  final String sex;
  final List<String> conditions;
  final List<String> allergies;
  final List<Map<String, String>> emergencyContacts;
  final String? responsibleDoctor;
  final String? clinicalNotes;
  final DateTime createdAt;
  final String createdBy;

  const Patient({
    required this.id,
    required this.fullName,
    this.nickname,
    this.photoUrl,
    required this.dateOfBirth,
    required this.sex,
    this.conditions = const [],
    this.allergies = const [],
    this.emergencyContacts = const [],
    this.responsibleDoctor,
    this.clinicalNotes,
    required this.createdAt,
    required this.createdBy,
  });

  Patient copyWith({
    String? id,
    String? fullName,
    String? nickname,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? sex,
    List<String>? conditions,
    List<String>? allergies,
    List<Map<String, String>>? emergencyContacts,
    String? responsibleDoctor,
    String? clinicalNotes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      responsibleDoctor: responsibleDoctor ?? this.responsibleDoctor,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'sex': sex,
      'conditions': conditions,
      'allergies': allergies,
      'emergencyContacts': emergencyContacts,
      'responsibleDoctor': responsibleDoctor,
      'clinicalNotes': clinicalNotes,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      nickname: map['nickname'] as String?,
      photoUrl: map['photoUrl'] as String?,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      sex: map['sex'] as String,
      conditions: (map['conditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      allergies: (map['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          [],
      responsibleDoctor: map['responsibleDoctor'] as String?,
      clinicalNotes: map['clinicalNotes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      createdBy: map['createdBy'] as String,
    );
  }
}
