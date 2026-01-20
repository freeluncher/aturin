import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final double amount;
  final String status; // 'Draft', 'Sent', 'Paid'
  final DateTime dueDate;
  final DateTime createdAt;
  final String? serverId;
  final bool isSynced;
  final bool isDeleted;

  const Invoice({
    required this.id,
    required this.projectId,
    required this.title,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.serverId,
    this.isSynced = false,
    this.isDeleted = false,
  });

  Invoice copyWith({
    String? id,
    String? projectId,
    String? title,
    double? amount,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
    String? serverId,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Invoice(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      serverId: serverId ?? this.serverId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    amount,
    status,
    dueDate,
    createdAt,
    serverId,
    isSynced,
    isDeleted,
  ];
}
