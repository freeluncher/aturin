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
  final String? clientEmail;
  final double totalBudget;
  // final double amountPaid; // Removed in v7
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
    this.clientEmail,
    this.totalBudget = 0.0,
    this.techStack,
    this.status = 1, // Default Active
    this.isSynced = false,
    this.isDeleted = false,
  });

  Project copyWith({
    String? id,
    String? serverId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? deadline,
    String? clientName,
    String? clientContact,
    String? clientEmail,
    double? totalBudget,
    String? techStack,
    int? status,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Project(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deadline: deadline ?? this.deadline,
      clientName: clientName ?? this.clientName,
      clientContact: clientContact ?? this.clientContact,
      clientEmail: clientEmail ?? this.clientEmail,
      totalBudget: totalBudget ?? this.totalBudget,
      techStack: techStack ?? this.techStack,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
