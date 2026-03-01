class PatientMember {
  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role; // admin, editor, viewer
  final String status; // active, pending
  final DateTime joinedAt;
  final String? invitedBy;

  const PatientMember({
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.invitedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'joinedAt': joinedAt.toIso8601String(),
      'invitedBy': invitedBy,
    };
  }

  factory PatientMember.fromMap(Map<String, dynamic> map) {
    return PatientMember(
      userId: map['userId'] as String,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String,
      status: map['status'] as String,
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'] as String)
          : DateTime.now(),
      invitedBy: map['invitedBy'] as String?,
    );
  }
}
