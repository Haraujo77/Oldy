import 'package:flutter/material.dart';

enum HealthMetricType {
  bloodPressure,
  heartRate,
  oxygenSaturation,
  temperature,
  glucose,
  weight,
  sleep,
  steps;

  String get label => switch (this) {
    bloodPressure => 'Pressão Arterial',
    heartRate => 'Frequência Cardíaca',
    oxygenSaturation => 'Saturação O₂',
    temperature => 'Temperatura',
    glucose => 'Glicemia',
    weight => 'Peso',
    sleep => 'Sono',
    steps => 'Passos',
  };

  String get shortLabel => switch (this) {
    bloodPressure => 'Pressão',
    heartRate => 'Batimentos',
    oxygenSaturation => 'Saturação',
    temperature => 'Temperatura',
    glucose => 'Glicemia',
    weight => 'Peso',
    sleep => 'Sono',
    steps => 'Passos',
  };

  String get unit => switch (this) {
    bloodPressure => 'mmHg',
    heartRate => 'bpm',
    oxygenSaturation => '%',
    temperature => '°C',
    glucose => 'mg/dL',
    weight => 'kg',
    sleep => 'h',
    steps => '',
  };

  IconData get icon => switch (this) {
    bloodPressure => Icons.bloodtype_outlined,
    heartRate => Icons.monitor_heart_outlined,
    oxygenSaturation => Icons.air_outlined,
    temperature => Icons.thermostat_outlined,
    glucose => Icons.water_drop_outlined,
    weight => Icons.monitor_weight_outlined,
    sleep => Icons.bedtime_outlined,
    steps => Icons.directions_walk_outlined,
  };

  Color get color => switch (this) {
    bloodPressure => const Color(0xFFE53935),
    heartRate => const Color(0xFFD81B60),
    oxygenSaturation => const Color(0xFF1E88E5),
    temperature => const Color(0xFFFB8C00),
    glucose => const Color(0xFF8E24AA),
    weight => const Color(0xFF43A047),
    sleep => const Color(0xFF3949AB),
    steps => const Color(0xFF00ACC1),
  };

  double get defaultMin => switch (this) {
    bloodPressure => 90,
    heartRate => 60,
    oxygenSaturation => 95,
    temperature => 36.0,
    glucose => 70,
    weight => 40,
    sleep => 6,
    steps => 3000,
  };

  double get defaultMax => switch (this) {
    bloodPressure => 140,
    heartRate => 100,
    oxygenSaturation => 100,
    temperature => 37.5,
    glucose => 140,
    weight => 120,
    sleep => 9,
    steps => 10000,
  };
}

class HealthMetric {
  final HealthMetricType metricType;
  final String frequency;
  final List<String> scheduledTimes;
  final double? targetMin;
  final double? targetMax;
  final bool remindersEnabled;

  const HealthMetric({
    required this.metricType,
    required this.frequency,
    this.scheduledTimes = const [],
    this.targetMin,
    this.targetMax,
    this.remindersEnabled = true,
  });

  HealthMetric copyWith({
    HealthMetricType? metricType,
    String? frequency,
    List<String>? scheduledTimes,
    double? targetMin,
    double? targetMax,
    bool? remindersEnabled,
  }) {
    return HealthMetric(
      metricType: metricType ?? this.metricType,
      frequency: frequency ?? this.frequency,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      targetMin: targetMin ?? this.targetMin,
      targetMax: targetMax ?? this.targetMax,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'metricType': metricType.name,
      'frequency': frequency,
      'scheduledTimes': scheduledTimes,
      'targetMin': targetMin,
      'targetMax': targetMax,
      'remindersEnabled': remindersEnabled,
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      metricType: HealthMetricType.values.byName(map['metricType'] as String),
      frequency: map['frequency'] as String? ?? 'Diário',
      scheduledTimes: List<String>.from(map['scheduledTimes'] ?? []),
      targetMin: (map['targetMin'] as num?)?.toDouble(),
      targetMax: (map['targetMax'] as num?)?.toDouble(),
      remindersEnabled: map['remindersEnabled'] as bool? ?? true,
    );
  }
}
