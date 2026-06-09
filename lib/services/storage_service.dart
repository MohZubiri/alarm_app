import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

class StorageService {
  static const String _remindersKey = 'reminders';
  static const String _lastIdKey = 'last_id';

  Future<List<Reminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_remindersKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Reminder.fromJson(e)).toList();
  }

  Future<void> save(List<Reminder> items) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_remindersKey, jsonEncode(jsonList));
  }

  Future<int> nextId() async {
    final prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_lastIdKey) ?? 0;
    final int next = current + 1;
    await prefs.setInt(_lastIdKey, next);
    return next;
  }

  static Future<String?> nameFor(int id) async {
    final storage = StorageService();
    final reminders = await storage.load();
    try {
      final reminder = reminders.firstWhere((r) => r.id == id);
      return reminder.name;
    } catch (e) {
      return null;
    }
  }
}
