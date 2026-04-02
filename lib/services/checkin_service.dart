import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CheckInService {
  static const String key = "checkin_history";

  /// Save a fair participation record with name, points, and timestamp.
  static Future<void> addCheckIn(String fairName, int points) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(key) ?? [];

    String formattedTime =
        DateFormat('dd MMM yyyy, hh:mm:ss a').format(DateTime.now());

    final newEntry = jsonEncode({
      "fairName": fairName,
      "points": points,
      "time": formattedTime,
    });

    history.add(newEntry);

    await prefs.setStringList(key, history);
  }

  /// Retrieve participation history.
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(key) ?? [];

    return history
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  /// Calculate total points earned across all participations.
  static Future<int> getTotalPoints() async {
    final history = await getHistory();
    int total = 0;
    for (final entry in history) {
      total += (entry['points'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  /// Clear all participation history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}