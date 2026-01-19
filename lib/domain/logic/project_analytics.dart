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
  /// - Invoiced: Menggunakan field `amountPaid` sebagai representasi tagihan yang sudah diproses/dibayar.
  ///   (Catatan: Idealnya ada tabel Invoice terpisah untuk 'tagihan terkirim' vs 'terbayar').
  FinancialBreakdown getFinancials(List<Task> tasks) {
    if (tasks.isEmpty) {
      return FinancialBreakdown(
        earned: 0,
        pending: totalBudget,
        invoiced: amountPaid,
      );
    }

    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = completedTasks / tasks.length;

    final earned = totalBudget * progress;
    final pending = totalBudget - earned;

    return FinancialBreakdown(
      earned: earned,
      pending: pending,
      invoiced: amountPaid,
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
