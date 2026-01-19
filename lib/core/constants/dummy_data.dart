import 'package:lucide_icons/lucide_icons.dart';

class DummyData {
  static const String revenue = 'Rp 15.000.000';
  static const String activeProjectsCount = '5';
  static const String deadlineTime = '2 Hari';

  static final List<Map<String, dynamic>> todaysTasks = [
    {
      'title': 'Revisi Desain App',
      'icon': LucideIcons.checkCircle,
      'isCompleted': true,
    },
    {
      'title': 'Meeting Klien A',
      'icon': LucideIcons.circle,
      'isCompleted': false,
    },
    {
      'title': 'Push Code Backend',
      'icon': LucideIcons.circle,
      'isCompleted': false,
    },
    {
      'title': 'Update Dokumentasi API',
      'icon': LucideIcons.circle,
      'isCompleted': false,
    },
  ];
}
