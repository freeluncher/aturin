class Project {
  final String id;
  final String? serverId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? deadline;
  final String? clientName;
  final String? clientContact;
  final double totalBudget;
  final double amountPaid;
  final String? techStack;
  final int status;
  final bool isSynced;
  final bool isDeleted;

  Project({
    required this.id,
    this.serverId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastUpdated,
    this.deadline,
    this.clientName,
    this.clientContact,
    this.totalBudget = 0.0,
    this.amountPaid = 0.0,
    this.techStack,
    this.status = 1, // Default Active
    this.isSynced = false,
    this.isDeleted = false,
  });
}
