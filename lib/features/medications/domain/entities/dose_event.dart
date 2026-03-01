class DoseEvent {
  final String id;
  final String medPlanId;
  final String medicationName;
  final String status; // 'pendente' | 'tomado' | 'atrasado' | 'pulado' | 'adiado'
  final DateTime scheduledAt;
  final DateTime? actualAt;
  final String? recordedBy;
  final String? skipReason;

  const DoseEvent({
    required this.id,
    required this.medPlanId,
    required this.medicationName,
    required this.status,
    required this.scheduledAt,
    this.actualAt,
    this.recordedBy,
    this.skipReason,
  });

  DoseEvent copyWith({
    String? id,
    String? medPlanId,
    String? medicationName,
    String? status,
    DateTime? scheduledAt,
    DateTime? actualAt,
    String? recordedBy,
    String? skipReason,
  }) {
    return DoseEvent(
      id: id ?? this.id,
      medPlanId: medPlanId ?? this.medPlanId,
      medicationName: medicationName ?? this.medicationName,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      actualAt: actualAt ?? this.actualAt,
      recordedBy: recordedBy ?? this.recordedBy,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medPlanId': medPlanId,
      'medicationName': medicationName,
      'status': status,
      'scheduledAt': scheduledAt.toIso8601String(),
      'actualAt': actualAt?.toIso8601String(),
      'recordedBy': recordedBy,
      'skipReason': skipReason,
    };
  }

  factory DoseEvent.fromMap(Map<String, dynamic> map) {
    return DoseEvent(
      id: map['id'] as String,
      medPlanId: map['medPlanId'] as String,
      medicationName: map['medicationName'] as String? ?? '',
      status: map['status'] as String? ?? 'pendente',
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.parse(map['scheduledAt'] as String)
          : DateTime.now(),
      actualAt: map['actualAt'] != null
          ? DateTime.parse(map['actualAt'] as String)
          : null,
      recordedBy: map['recordedBy'] as String?,
      skipReason: map['skipReason'] as String?,
    );
  }
}
