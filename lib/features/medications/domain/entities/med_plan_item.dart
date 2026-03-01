class MedPlanItem {
  final String id;
  final String medicationName;
  final String? activeIngredient;
  final String form;
  final String dosage;
  final String frequencyType; // 'interval' | 'fixed'
  final int? intervalHours;
  final List<String> scheduledTimes;
  final DateTime startDate;
  final DateTime? endDate;
  final bool continuous;
  final String? instructions;
  final String? notes;
  final String? photoUrl;
  final String? createdBy;
  final DateTime createdAt;

  const MedPlanItem({
    required this.id,
    required this.medicationName,
    this.activeIngredient,
    required this.form,
    required this.dosage,
    required this.frequencyType,
    this.intervalHours,
    required this.scheduledTimes,
    required this.startDate,
    this.endDate,
    this.continuous = false,
    this.instructions,
    this.notes,
    this.photoUrl,
    this.createdBy,
    required this.createdAt,
  });

  MedPlanItem copyWith({
    String? id,
    String? medicationName,
    String? activeIngredient,
    String? form,
    String? dosage,
    String? frequencyType,
    int? intervalHours,
    List<String>? scheduledTimes,
    DateTime? startDate,
    DateTime? endDate,
    bool? continuous,
    String? instructions,
    String? notes,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MedPlanItem(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      form: form ?? this.form,
      dosage: dosage ?? this.dosage,
      frequencyType: frequencyType ?? this.frequencyType,
      intervalHours: intervalHours ?? this.intervalHours,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      continuous: continuous ?? this.continuous,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationName': medicationName,
      'activeIngredient': activeIngredient,
      'form': form,
      'dosage': dosage,
      'frequencyType': frequencyType,
      'intervalHours': intervalHours,
      'scheduledTimes': scheduledTimes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'continuous': continuous,
      'instructions': instructions,
      'notes': notes,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedPlanItem.fromMap(Map<String, dynamic> map) {
    return MedPlanItem(
      id: map['id'] as String,
      medicationName: map['medicationName'] as String,
      activeIngredient: map['activeIngredient'] as String?,
      form: map['form'] as String? ?? 'Comprimido',
      dosage: map['dosage'] as String? ?? '',
      frequencyType: map['frequencyType'] as String? ?? 'fixed',
      intervalHours: map['intervalHours'] as int?,
      scheduledTimes: List<String>.from(map['scheduledTimes'] ?? []),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      continuous: map['continuous'] as bool? ?? false,
      instructions: map['instructions'] as String?,
      notes: map['notes'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
