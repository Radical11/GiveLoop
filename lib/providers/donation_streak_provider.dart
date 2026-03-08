import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DonationStreakProvider extends ChangeNotifier {
  List<DateTime> _donations = [];
  List<DateTime> get donations => _donations;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('donation_timestamps') ?? [];
    _donations = raw.map((s) => DateTime.parse(s)).toList();
    notifyListeners();
  }

  Future<void> recordDonation() async {
    final now = DateTime.now();
    _donations.add(now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'donation_timestamps',
      _donations.map((d) => d.toIso8601String()).toList(),
    );
    notifyListeners();
  }

  int getActivityLevel(int monthIndex, int weekIndex) {
    final count = _donations.where((d) {
      final weekOfMonth = ((d.day - 1) / 7).floor();
      return d.month - 1 == monthIndex && weekOfMonth == weekIndex;
    }).length;

    if (count == 0) return 0;
    if (count == 1) return 1;
    if (count <= 3) return 2;
    if (count <= 5) return 3;
    return 4;
  }

  int get thisMonthCount {
    final now = DateTime.now();
    return _donations
        .where((d) => d.month == now.month && d.year == now.year)
        .length;
  }

  int get currentStreakWeeks {
    if (_donations.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
    while (true) {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasDonation = _donations.any(
        (d) =>
            d.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            d.isBefore(weekEnd),
      );
      if (!hasDonation) break;
      streak++;
      weekStart = weekStart.subtract(const Duration(days: 7));
      if (streak > 52) break;
    }
    return streak;
  }

  int get longestStreakWeeks {
    if (_donations.isEmpty) return 0;
    _donations.sort();
    int longest = 0;
    int current = 1;
    for (int i = 1; i < _donations.length; i++) {
      final diff = _donations[i].difference(_donations[i - 1]).inDays;
      if (diff <= 7) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest == 0 ? 1 : longest;
  }
}
