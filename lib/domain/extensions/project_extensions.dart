import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart'; // Import domain Task

extension ProjectExtensions on Project {
  // --- Progress Calculation ---
  // Requires passing calculation result or list of tasks
  double calculateProgress(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return completed / tasks.length;
  }

  // --- Urgency (Deadline) ---
  String get urgencyText {
    if (deadline == null) return 'No Deadline';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(
      deadline!.year,
      deadline!.month,
      deadline!.day,
    ); // Normalize

    final diff = d.difference(today).inDays;

    if (diff < 0) {
      return 'Terlambat ${diff.abs()} hari';
    } else if (diff == 0) {
      return 'Hari ini';
    } else {
      return '$diff hari lagi';
    }
  }

  Color get urgencyColor {
    if (deadline == null) return Colors.grey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(deadline!.year, deadline!.month, deadline!.day);

    final diff = d.difference(today).inDays;

    if (diff < 0) return Colors.red;
    if (diff <= 3) return Colors.orange; // High urgency
    return Colors.green; // Safe
  }

  // --- Finance ---
  // Financial logic moved to ProjectAnalytics extension with new Invoice table support

  // --- Tech Icons (JSON Parsing) ---
  List<String> get parsedTechStack {
    if (techStack == null || techStack!.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(techStack!);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }
}
