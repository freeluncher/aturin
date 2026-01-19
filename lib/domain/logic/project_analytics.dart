import '../models/project.dart';
import '../models/task.dart';

enum ProjectHealthStatus { onTrack, atRisk, behindSchedule }

class FinancialBreakdown {
  final double earned;
  final double pending;
  final double invoiced;

  FinancialBreakdown({
    required this.earned,
    required this.pending,
    required this.invoiced,
  });
}

extension ProjectAnalytics on Project {
  /// Menghitung Project Health berdasarkan rasio waktu vs rasio tugas selesai.
  ///
  /// Logic:
  /// - Time Ratio = (Hari Berlalu) / (Total Durasi Proyek)
  /// - Task Ratio = (Tugas Selesai) / (Total Tugas)
  /// - Jika Task Ratio >= Time Ratio, maka 'On Track'.
  /// - Jika selisih < 15%, maka 'At Risk'.
  /// - Jika selisih >= 15%, maka 'Behind Schedule'.
  ProjectHealthStatus getHealth(List<Task> tasks) {
    if (status == 3) return ProjectHealthStatus.onTrack; // Completed
    if (deadline == null) return ProjectHealthStatus.onTrack; // No deadline

    final now = DateTime.now();
    final totalDuration = deadline!.difference(createdAt).inDays;
    final elapsedDays = now.difference(createdAt).inDays;

    // Jika belum mulai atau durasi 0
    if (totalDuration <= 0) return ProjectHealthStatus.atRisk;
    if (elapsedDays <= 0) return ProjectHealthStatus.onTrack;

    final timeRatio = (elapsedDays / totalDuration).clamp(0.0, 1.0);

    if (tasks.isEmpty) {
      // Belum ada tugas, tapi waktu berjalan
      return timeRatio > 0.1
          ? ProjectHealthStatus.behindSchedule
          : ProjectHealthStatus.onTrack;
    }

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final taskRatio = completedTasks / tasks.length;

    if (taskRatio >= timeRatio) {
      return ProjectHealthStatus.onTrack;
    } else if ((timeRatio - taskRatio) < 0.15) {
      return ProjectHealthStatus.atRisk;
    } else {
      return ProjectHealthStatus.behindSchedule;
    }
  }

  /// Menghitung Breakdown Finansial Proyek.
  ///
  /// Logic:
  /// - Earned: Estimasi nilai kerja yang sudah selesai (Budget * Progress).
  /// - Pending: Sisa budget dari pekerjaan yang belum selesai (Budget - Earned).
  /// - Invoiced: Total dari semua Invoice yang berstatus 'Paid'.
  FinancialBreakdown getFinancials(
    List<Task> tasks, {
    List<dynamic> invoices = const [],
  }) {
    // Note: 'invoices' parameter is dynamic here to avoid heavy dependency issues
    // if 'Invoice' type is not available in domain/models/project.dart context yet.
    // In strict architecture, we should map database 'Invoice' to domain 'Invoice'.
    // For now assuming existing drift class or domain class is compatible if passed.

    // Calculate total invoiced (Paid status)
    double totalPaid = 0;
    for (var inv in invoices) {
      // Assuming Invoice object has 'status' and 'amount'
      // Check if status is 'Paid' (case insensitive or exact string)
      final status = (inv.status as String).toLowerCase();
      if (status == 'paid') {
        totalPaid += (inv.amount as double);
      }
    }

    if (tasks.isEmpty) {
      return FinancialBreakdown(
        earned: 0,
        pending: totalBudget,
        invoiced: totalPaid,
      );
    }

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = completedTasks / tasks.length;

    final earned = totalBudget * progress;
    final pending = totalBudget - earned;

    return FinancialBreakdown(
      earned: earned,
      pending: pending,
      invoiced: totalPaid,
    );
  }

  /// Menghitung Urgency Score untuk pengurutan prioritas.
  ///
  /// Score semakin tinggi = Semakin mendesak.
  /// Logic:
  /// - Score dasar: 100
  /// - Dikurangi jumlah hari menuju deadline (Deadline dekat = Score tinggi).
  /// - Ditambah bobot tugas kritis yang belum selesai (Saat ini semua tugas unfinshed dianggap kritis).
  ///
  /// Formula: 100 - (DaysRemaining) + (UnfinishedTasks * 2)
  double getUrgencyScore(List<Task> tasks) {
    if (status == 3) return -100; // Completed projects have low urgency
    if (deadline == null) return 0;

    final daysRemaining = deadline!.difference(DateTime.now()).inDays;
    final unfinishedTasks = tasks.where((t) => !t.isCompleted).length;

    // Criticality weight (bisa disesuaikan jika ada field priority nanti)
    const taskWeight = 2.0;

    // Semakin sedikit hari tersisa, score semakin besar (karena daysRemaining makin kecil/negatif)
    return 100.0 - daysRemaining + (unfinishedTasks * taskWeight);
  }
}
