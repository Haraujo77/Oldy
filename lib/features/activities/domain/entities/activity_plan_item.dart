class ActivityPlanItem {
  final String id;
  final String activityName;
  final String category;
  final String frequencyType; // 'fixed' | 'interval' | 'weekly'
  final int? intervalHours;
  final List<String> scheduledTimes;
  final List<int> daysOfWeek; // 1=Mon..7=Sun (for 'weekly')
  final DateTime startDate;
  final DateTime? endDate;
  final bool continuous;
  final int? durationMinutes;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const ActivityPlanItem({
    required this.id,
    required this.activityName,
    required this.category,
    required this.frequencyType,
    this.intervalHours,
    required this.scheduledTimes,
    this.daysOfWeek = const [],
    required this.startDate,
    this.endDate,
    this.continuous = true,
    this.durationMinutes,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  ActivityPlanItem copyWith({
    String? id,
    String? activityName,
    String? category,
    String? frequencyType,
    int? intervalHours,
    List<String>? scheduledTimes,
    List<int>? daysOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    bool? continuous,
    int? durationMinutes,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ActivityPlanItem(
      id: id ?? this.id,
      activityName: activityName ?? this.activityName,
      category: category ?? this.category,
      frequencyType: frequencyType ?? this.frequencyType,
      intervalHours: intervalHours ?? this.intervalHours,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      continuous: continuous ?? this.continuous,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityName': activityName,
      'category': category,
      'frequencyType': frequencyType,
      'intervalHours': intervalHours,
      'scheduledTimes': scheduledTimes,
      'daysOfWeek': daysOfWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'continuous': continuous,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityPlanItem.fromMap(Map<String, dynamic> map) {
    return ActivityPlanItem(
      id: map['id'] as String,
      activityName: map['activityName'] as String,
      category: map['category'] as String? ?? 'Outro',
      frequencyType: map['frequencyType'] as String? ?? 'fixed',
      intervalHours: map['intervalHours'] as int?,
      scheduledTimes: List<String>.from(map['scheduledTimes'] ?? []),
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      continuous: map['continuous'] as bool? ?? true,
      durationMinutes: map['durationMinutes'] as int?,
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
