class Invite {
  final String id;
  final String code;
  final String patientId;
  final String role;
  final String email;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // pending, accepted, expired

  const Invite({
    required this.id,
    required this.code,
    required this.patientId,
    required this.role,
    required this.email,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'patientId': patientId,
      'role': role,
      'email': email,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status,
    };
  }

  factory Invite.fromMap(Map<String, dynamic> map) {
    return Invite(
      id: map['id'] as String,
      code: map['code'] as String,
      patientId: map['patientId'] as String,
      role: map['role'] as String,
      email: map['email'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : DateTime.now(),
      status: map['status'] as String,
    );
  }
}
