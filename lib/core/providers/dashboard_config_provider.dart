import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/dashboard_config.dart';

// Provider for SharedPreferences (Async)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class DashboardConfigNotifier extends Notifier<DashboardConfig> {
  static const String _prefsKey = 'dashboard_config';

  @override
  DashboardConfig build() {
    // Attempt to load from prefs immediately if available
    // Note: sharedPreferencesProvider must be overridden in main.dart
    Future.microtask(() => _loadConfig());
    return DashboardConfig.defaults();
  }

  void _loadConfig() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        state = DashboardConfig.fromJson(jsonString);
      }
    } catch (e) {
      // Fallback to defaults on error
    }
  }

  Future<void> _saveConfig() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, state.toJson());
  }

  void reorder(int oldIndex, int newIndex) {
    state = state.reorder(oldIndex, newIndex);
    _saveConfig();
  }

  void toggleVisibility(String id) {
    state = state.toggleVisibility(id);
    _saveConfig();
  }

  void resetToDefaults() {
    state = DashboardConfig.defaults();
    _saveConfig();
  }
}

// Provider for DashboardConfig
final dashboardConfigProvider =
    NotifierProvider<DashboardConfigNotifier, DashboardConfig>(() {
      return DashboardConfigNotifier();
    });
