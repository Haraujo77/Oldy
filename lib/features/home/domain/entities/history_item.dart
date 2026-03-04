import 'package:flutter/material.dart';

enum HistoryItemType { activity, healthLog, doseEvent }

class HistoryItem {
  final HistoryItemType type;
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color? iconColor;
  final Object? data;

  const HistoryItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    this.iconColor,
    this.data,
  });
}
