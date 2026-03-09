import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BreathingStorageService {
  static const _prefsKey = 'breathing_sessions';

  /// Add a session (seconds) stamped with current time.
  Future<void> addSession(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    final entry = jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'duration': seconds,
    });
    list.add(entry);
    await prefs.setStringList(_prefsKey, list);
  }

  /// Return raw sessions as maps with keys 'ts' and 'duration'.
  Future<List<Map<String, int>>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    final out = <Map<String, int>>[];
    for (final s in list) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final ts = (m['ts'] as num).toInt();
        final dur = (m['duration'] as num).toInt();
        out.add({'ts': ts, 'duration': dur});
      } catch (_) {
        // ignore bad entries
      }
    }
    return out;
  }

  /// Return totals (in minutes) for the last 7 days ending today.
  /// The list is ordered from oldest -> newest (7 items).
  Future<List<double>> getLast7DaysTotalsInMinutes() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();
    final days = List<DateTime>.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      return d;
    });

    // Map day (YYYY-MM-DD) -> total seconds
    final Map<String, int> totals = {};
    for (final s in sessions) {
      final ts = DateTime.fromMillisecondsSinceEpoch(s['ts']!);
      final dayKey = '${ts.year}-${ts.month}-${ts.day}';
      totals[dayKey] = (totals[dayKey] ?? 0) + (s['duration'] ?? 0);
    }

    // Build result list aligned with days[]
    final List<double> result = [];
    for (final d in days) {
      final key = '${d.year}-${d.month}-${d.day}';
      final seconds = totals[key] ?? 0;
      final minutes = seconds / 60.0;
      result.add(minutes);
    }

    return result;
  }

  /// Optionally clear stored sessions (useful for testing)
  Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
