import 'dart:convert';
import 'package:equatable/equatable.dart';

class DashboardConfig extends Equatable {
  final List<String> visibleSectionIds;
  final List<String> hiddenSectionIds;

  const DashboardConfig({
    required this.visibleSectionIds,
    required this.hiddenSectionIds,
  });

  // Default configuration
  factory DashboardConfig.defaults() {
    return const DashboardConfig(
      visibleSectionIds: [
        'todays_tasks',
        'featured_project',
        'financial_overview',
        'workload_summary',
      ],
      hiddenSectionIds: [],
    );
  }

  DashboardConfig copyWith({
    List<String>? visibleSectionIds,
    List<String>? hiddenSectionIds,
  }) {
    return DashboardConfig(
      visibleSectionIds: visibleSectionIds ?? this.visibleSectionIds,
      hiddenSectionIds: hiddenSectionIds ?? this.hiddenSectionIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visibleSectionIds': visibleSectionIds,
      'hiddenSectionIds': hiddenSectionIds,
    };
  }

  factory DashboardConfig.fromMap(Map<String, dynamic> map) {
    return DashboardConfig(
      visibleSectionIds: List<String>.from(map['visibleSectionIds'] ?? []),
      hiddenSectionIds: List<String>.from(map['hiddenSectionIds'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardConfig.fromJson(String source) =>
      DashboardConfig.fromMap(json.decode(source));

  @override
  List<Object> get props => [visibleSectionIds, hiddenSectionIds];

  // Helper to reorder
  DashboardConfig reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = List<String>.from(visibleSectionIds);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    return copyWith(visibleSectionIds: items);
  }

  // Helper to toggle visibility
  DashboardConfig toggleVisibility(String id) {
    final isVisible = visibleSectionIds.contains(id);

    if (isVisible) {
      // Hide
      return copyWith(
        visibleSectionIds: List.from(visibleSectionIds)..remove(id),
        hiddenSectionIds: List.from(hiddenSectionIds)..add(id),
      );
    } else {
      // Show (append to end)
      return copyWith(
        visibleSectionIds: List.from(visibleSectionIds)..add(id),
        hiddenSectionIds: List.from(hiddenSectionIds)..remove(id),
      );
    }
  }
}
